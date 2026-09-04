"""
Scrape all European Youth Portal opportunity details.
Supports resume, delay, limit, and quality filtering.

Usage:
  python european_youth_scraper.py
  python european_youth_scraper.py --limit 10
  python european_youth_scraper.py --resume
  python european_youth_scraper.py --delay 2.0
  python european_youth_scraper.py --resume --limit 50 --delay 1.5
"""

import json
import time
import sys
import argparse
import re
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime

import requests
from bs4 import BeautifulSoup
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

BASE_URL = "https://youth.europa.eu"
URL_CACHE_FILE = Path("european_youth_project_urls.json")
OUTPUT_FILE = Path("european_youth_projects.json")
REJECTED_FILE = Path("european_youth_rejected_projects.json")
FAILED_FILE = Path("european_youth_failed_urls.json")
RESUME_FILE = Path("european_youth_scraper_resume.json")
USER_AGENT = "ErasmusSimulationAcademicProject/1.0"

MOJIBAKE_CHARS = {'Ã', 'Ä', 'Å', 'â', 'ã', 'ä', 'å'}
MIN_DESCRIPTION_LENGTH = 150


@dataclass
class OpportunityProject:
    sourceUrl: str
    sourceName: str = "European Youth Portal"
    sourceLanguage: str = "en"
    recordType: str = "esc_opportunity"
    isActiveOpportunity: bool = True
    title: str = ""
    description: str = ""
    country: str = ""
    town: str = ""
    organisation: str = ""
    duration: str = ""
    date_start: str = ""
    date_end: str = ""
    date_application_end: str = ""
    applicationDeadline: str = ""
    is_esc_related: bool = False
    additionalFields: Dict = None
    scrapedAt: str = ""
    
    def __post_init__(self):
        if self.additionalFields is None:
            self.additionalFields = {}
        if not self.scrapedAt:
            self.scrapedAt = datetime.now().isoformat()


@dataclass
class ScrapeRejection:
    url: str
    reason: str
    scrapedAt: str = ""
    
    def __post_init__(self):
        if not self.scrapedAt:
            self.scrapedAt = datetime.now().isoformat()


@dataclass
class ScrapeFailed:
    url: str
    error: str
    attempts: int = 1
    lastAttempt: str = ""
    
    def __post_init__(self):
        if not self.lastAttempt:
            self.lastAttempt = datetime.now().isoformat()


def create_session() -> requests.Session:
    session = requests.Session()
    session.headers.update({"User-Agent": USER_AGENT})
    retries = Retry(
        total=3,
        backoff_factor=1,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET", "POST"],
    )
    session.mount("https://", HTTPAdapter(max_retries=retries))
    session.mount("http://", HTTPAdapter(max_retries=retries))
    return session


def load_urls() -> List[str]:
    """Load collected URLs from URL cache."""
    if not URL_CACHE_FILE.exists():
        raise FileNotFoundError(f"{URL_CACHE_FILE.name} not found. Run collect_european_youth_urls.py first.")
    data = json.loads(URL_CACHE_FILE.read_text(encoding='utf-8'))
    urls = data.get("project_urls", [])
    print(f"Loaded {len(urls)} URLs from {URL_CACHE_FILE.name}")
    return urls


def load_resume_state() -> Dict:
    """Load resume state if it exists."""
    if RESUME_FILE.exists():
        state = json.loads(RESUME_FILE.read_text(encoding='utf-8'))
        print(f"Resuming from index {state.get('lastIndex', -1) + 1}")
        return state
    return {
        "processed": [],
        "projects": [],
        "rejected": [],
        "failed": [],
        "lastIndex": -1,
        "startedAt": datetime.now().isoformat(),
    }


def save_state(state: Dict) -> None:
    """Save current state for resume."""
    RESUME_FILE.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding='utf-8')


def save_projects(projects: List) -> None:
    """Save accepted projects."""
    data = {
        "source": "European Youth Portal",
        "language": "en",
        "projectCount": len(projects),
        "projects": projects,
        "savedAt": datetime.now().isoformat(),
    }
    OUTPUT_FILE.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"Saved {len(projects)} projects to {OUTPUT_FILE.name}")


def save_rejected(rejected: List) -> None:
    """Save rejected projects."""
    if not rejected:
        return
    data = {
        "rejectionCount": len(rejected),
        "rejections": rejected,
        "savedAt": datetime.now().isoformat(),
    }
    REJECTED_FILE.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"Saved {len(rejected)} rejections to {REJECTED_FILE.name}")


def save_failed(failed: List) -> None:
    """Save failed URLs."""
    if not failed:
        return
    data = {
        "failureCount": len(failed),
        "failures": failed,
        "savedAt": datetime.now().isoformat(),
    }
    FAILED_FILE.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"Saved {len(failed)} failures to {FAILED_FILE.name}")


def has_mojibake(text: str) -> bool:
    """Detect encoding corruption."""
    if not text:
        return False
    return any(char in text for char in MOJIBAKE_CHARS)


def validate_project(proj: OpportunityProject) -> Tuple[bool, Optional[str]]:
    """Validate project quality."""
    if not proj.title or not proj.title.strip():
        return False, "empty_title"
    
    if not proj.description or len(proj.description) < MIN_DESCRIPTION_LENGTH:
        return False, f"short_description (len={len(proj.description or '')})"
    
    if has_mojibake(proj.title) or has_mojibake(proj.description):
        return False, "encoding_corruption"
    
    if not proj.sourceUrl or "youth.europa.eu" not in proj.sourceUrl:
        return False, "invalid_source_url"
    
    return True, None


def extract_project_data(html: str, url: str) -> Optional[OpportunityProject]:
    """Extract project data from detail page HTML."""
    try:
        soup = BeautifulSoup(html, "html.parser")
        
        proj = OpportunityProject(sourceUrl=url)
        
        # Try to extract title
        title_elem = soup.select_one("h1, .page-title, [data-page-title]")
        if title_elem:
            proj.title = title_elem.get_text(strip=True)
        
        # Try to extract description
        desc_candidates = soup.select(".field--name-description, .node__content, [role='main'] p, .content")
        if desc_candidates:
            desc_text = " ".join(elem.get_text(strip=True) for elem in desc_candidates[:3])
            proj.description = desc_text[:1000]  # truncate if too long
        
        # Try to extract country
        country_elem = soup.select_one(".field--name-country, [data-country]")
        if country_elem:
            proj.country = country_elem.get_text(strip=True)
        
        # Try to extract town
        town_elem = soup.select_one(".field--name-town, [data-town]")
        if town_elem:
            proj.town = town_elem.get_text(strip=True)
        
        # Try to extract organisation
        org_elem = soup.select_one(".field--name-organisation, [data-organisation]")
        if org_elem:
            proj.organisation = org_elem.get_text(strip=True)
        
        # Try to extract dates
        dates = soup.select(".field--name-date-start, .field--name-date-end, .field--name-date-application-end, [data-date]")
        for date_elem in dates:
            text = date_elem.get_text(strip=True)
            parent_class = date_elem.get("class", [])
            if any("start" in str(c) for c in parent_class):
                proj.date_start = text
            elif any("end" in str(c) and "application" not in str(c) for c in parent_class):
                proj.date_end = text
            elif any("application" in str(c) for c in parent_class):
                proj.date_application_end = text
                proj.applicationDeadline = text
        
        # Try to extract duration
        duration_elem = soup.select_one(".field--name-duration, [data-duration]")
        if duration_elem:
            proj.duration = duration_elem.get_text(strip=True)
        
        # Try to extract ESC related flag
        esc_text = html.lower()
        if "esc" in esc_text or "european solidarity corps" in esc_text:
            proj.is_esc_related = True
        
        return proj if proj.title else None
    except Exception as e:
        print(f"    Error extracting data: {e}")
        return None


def scrape_opportunity(session: requests.Session, url: str) -> Tuple[Optional[OpportunityProject], Optional[str]]:
    """Scrape single opportunity detail page."""
    try:
        response = session.get(url, timeout=20)
        response.raise_for_status()
        response.encoding = response.apparent_encoding or "utf-8"
        
        proj = extract_project_data(response.text, url)
        if not proj:
            return None, "no_data_extracted"
        
        is_valid, reason = validate_project(proj)
        if not is_valid:
            return None, reason or "unknown_validation_error"
        
        return proj, None
    except requests.exceptions.RequestException as e:
        return None, f"request_error: {str(e)[:100]}"
    except Exception as e:
        return None, f"parse_error: {str(e)[:100]}"


def main():
    parser = argparse.ArgumentParser(description="Scrape European Youth Portal opportunity details")
    parser.add_argument("--limit", type=int, default=None, help="Limit number of URLs to process")
    parser.add_argument("--resume", action="store_true", help="Resume from last checkpoint")
    parser.add_argument("--delay", type=float, default=0.5, help="Delay between requests (seconds)")
    args = parser.parse_args()
    
    print("="*60)
    print("European Youth Portal Opportunity Scraper")
    print("="*60)
    print(f"Limit: {args.limit or 'unlimited'}")
    print(f"Delay: {args.delay}s per request")
    print(f"Resume: {args.resume}")
    print()
    
    # Load URLs
    urls = load_urls()
    if args.limit:
        urls = urls[:args.limit]
        print(f"Limited to {len(urls)} URLs")
    
    # Load or init state
    state = load_resume_state() if args.resume else {
        "processed": [],
        "projects": [],
        "rejected": [],
        "failed": [],
        "lastIndex": -1,
        "startedAt": datetime.now().isoformat(),
    }
    
    session = create_session()
    start_idx = state.get("lastIndex", -1) + 1
    
    print(f"Starting from index {start_idx} of {len(urls)}")
    print()
    
    for idx in range(start_idx, len(urls)):
        url = urls[idx]
        print(f"[{idx+1}/{len(urls)}] {url}")
        
        # Scrape
        proj, error = scrape_opportunity(session, url)
        
        if proj:
            print(f"  ✓ Accepted")
            state["projects"].append(asdict(proj))
        elif error:
            print(f"  ✗ Rejected: {error}")
            state["rejected"].append(asdict(ScrapeRejection(url=url, reason=error)))
        else:
            print(f"  ✗ Failed: unknown error")
            state["failed"].append(asdict(ScrapeFailed(url=url, error="unknown")))
        
        state["processed"].append(url)
        state["lastIndex"] = idx
        
        # Save state periodically
        if (idx - start_idx + 1) % 10 == 0:
            save_state(state)
            save_projects(state["projects"])
            save_rejected(state["rejected"])
            save_failed(state["failed"])
            print(f"  Checkpoint: {len(state['projects'])} accepted, {len(state['rejected'])} rejected")
        
        # Delay
        time.sleep(args.delay)
    
    # Final save
    print()
    print("="*60)
    print("SCRAPING COMPLETE")
    print("="*60)
    print(f"Total processed: {len(state['processed'])}")
    print(f"Accepted projects: {len(state['projects'])}")
    print(f"Rejected records: {len(state['rejected'])}")
    print(f"Failed URLs: {len(state['failed'])}")
    
    save_projects(state["projects"])
    save_rejected(state["rejected"])
    save_failed(state["failed"])
    
    # Cleanup resume file if complete
    if len(state['processed']) == len(urls):
        if RESUME_FILE.exists():
            RESUME_FILE.unlink()
        print("Resume file cleaned (complete).")
    
    print("Done.")


if __name__ == "__main__":
    main()
