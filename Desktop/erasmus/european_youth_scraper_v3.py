#!/usr/bin/env python
"""
European Youth Portal Opportunity Scraper v3
Extracts opportunity details with proper HTML parsing
"""

import requests
from bs4 import BeautifulSoup
import json
import time
import argparse
import re
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, asdict
from typing import Optional, List, Tuple
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

@dataclass
class OpportunityProject:
    """Data model for opportunity project"""
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
    additionalFields: dict = None
    scrapedAt: str = ""

    def __post_init__(self):
        if self.additionalFields is None:
            self.additionalFields = {}
        if not self.scrapedAt:
            self.scrapedAt = datetime.utcnow().isoformat() + "Z"


@dataclass
class ScrapeRejection:
    """Rejected record tracking"""
    url: str
    reason: str
    scrapedAt: str = ""

    def __post_init__(self):
        if not self.scrapedAt:
            self.scrapedAt = datetime.utcnow().isoformat() + "Z"


@dataclass
class ScrapeFailed:
    """Failed URL tracking"""
    url: str
    error: str
    attempts: int = 1
    lastAttempt: str = ""

    def __post_init__(self):
        if not self.lastAttempt:
            self.lastAttempt = datetime.utcnow().isoformat() + "Z"


def create_session():
    """Create requests session with retry backoff"""
    session = requests.Session()
    retry_strategy = Retry(
        total=3,
        backoff_factor=1,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["HEAD", "GET", "OPTIONS"]
    )
    adapter = HTTPAdapter(max_retries=retry_strategy)
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    return session


def extract_text_after_heading(soup: BeautifulSoup, heading_text: str, max_paragraphs: int = 5) -> str:
    """Extract text from paragraphs following an h6 heading"""
    # Find h6 with the specified text
    for h6 in soup.find_all("h6"):
        if heading_text.lower() in h6.get_text().lower():
            # Get following p tags
            texts = []
            sibling = h6.find_next_sibling()
            count = 0
            while sibling and count < max_paragraphs:
                if sibling.name == "p":
                    text = sibling.get_text(strip=True)
                    if text:
                        texts.append(text)
                    count += 1
                elif sibling.name == "h6":  # Stop at next heading
                    break
                sibling = sibling.find_next_sibling()
            return " ".join(texts).strip()
    return ""


def extract_date_from_text(text: str) -> Tuple[str, str]:
    """Extract date range from text like 'From 06/07/2026 to 30/12/2026'"""
    # Pattern: "From DD/MM/YYYY to DD/MM/YYYY"
    pattern = r"from\s+(\d{1,2}/\d{1,2}/\d{4})\s+to\s+(\d{1,2}/\d{1,2}/\d{4})"
    match = re.search(pattern, text, re.IGNORECASE)
    if match:
        return match.group(1), match.group(2)
    return "", ""


def extract_deadline_from_text(text: str) -> str:
    """Extract deadline date from text like 'Application deadline: 21/06/2026 23:23'"""
    # Pattern: "DD/MM/YYYY HH:MM or similar"
    pattern = r"(\d{1,2}/\d{1,2}/\d{4})\s+(\d{1,2}:\d{2})"
    match = re.search(pattern, text)
    if match:
        return f"{match.group(1)} {match.group(2)}"
    return ""


def has_mojibake(text: str) -> bool:
    """Check for common encoding corruption markers"""
    mojibake_chars = ['Ã', 'Ä', 'Å', 'â', 'ã', 'ä', 'å', 'Â', 'À', 'Á', 'É', 'È']
    return any(char in text for char in mojibake_chars)


def extract_project_data(html: str, url: str) -> Tuple[Optional[OpportunityProject], str]:
    """Extract project data from HTML"""
    try:
        soup = BeautifulSoup(html, "html.parser")
        
        # Extract title
        title_elem = soup.find("h1", class_="od-title")
        title = title_elem.get_text(strip=True) if title_elem else ""
        
        # Extract organisation
        org_elem = soup.find("h3")
        organisation = org_elem.get_text(strip=True) if org_elem else ""
        
        # Extract location (town, country)
        location_elem = soup.find("p", class_="esc-standard-location")
        location_text = location_elem.get_text(strip=True) if location_elem else ""
        
        # Parse location - format is usually "Town, Country"
        country = ""
        town = ""
        if location_text:
            parts = location_text.split(",")
            if len(parts) >= 2:
                town = parts[0].strip()
                country = parts[1].strip()
            elif len(parts) == 1:
                country = parts[0].strip()
        
        # Extract description (first large paragraph after h6:"Description")
        description = extract_text_after_heading(soup, "Description", max_paragraphs=1)
        
        # Extract dates
        dates_text = extract_text_after_heading(soup, "Activity dates", max_paragraphs=1)
        date_start, date_end = extract_date_from_text(dates_text)
        
        # Extract activity location (may have more detail)
        activity_location = extract_text_after_heading(soup, "Activity location", max_paragraphs=1)
        
        # Extract deadline
        deadline_text = extract_text_after_heading(soup, "Deadline for applications", max_paragraphs=1)
        date_application_end = extract_deadline_from_text(deadline_text)
        
        # Check if ESC related
        full_text = soup.get_text().lower()
        is_esc_related = "european solidarity corps" in full_text or "esc" in full_text
        
        # Calculate duration
        duration = extract_text_after_heading(soup, "Activity type", max_paragraphs=1)
        
        # Create project object
        proj = OpportunityProject(
            sourceUrl=url,
            title=title,
            description=description,
            country=country,
            town=town,
            organisation=organisation,
            duration=duration,
            date_start=date_start,
            date_end=date_end,
            date_application_end=date_application_end,
            applicationDeadline=date_application_end,
            is_esc_related=is_esc_related
        )
        
        return proj, None
    
    except Exception as e:
        return None, f"parse_error: {str(e)}"


def validate_project(proj: OpportunityProject) -> Tuple[bool, str]:
    """Validate project data quality"""
    
    # Check for empty title
    if not proj.title or len(proj.title.strip()) == 0:
        return False, "empty_title"
    
    # Check for minimum description length
    if not proj.description or len(proj.description) < 50:
        return False, "short_description"
    
    # Check for mojibake
    if has_mojibake(proj.title) or has_mojibake(proj.description):
        return False, "encoding_corruption"
    
    # Check for valid source URL
    if not proj.sourceUrl or "youth.europa.eu" not in proj.sourceUrl:
        return False, "invalid_source_url"
    
    return True, ""


def load_urls() -> List[str]:
    """Load project URLs from collection file"""
    json_path = Path("european_youth_project_urls.json")
    if not json_path.exists():
        print(f"ERROR: {json_path} not found")
        return []
    
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
        return data.get("project_urls", [])


def load_resume_state() -> dict:
    """Load checkpoint state if resuming"""
    resume_file = Path("european_youth_scraper_resume.json")
    if resume_file.exists():
        with open(resume_file, "r", encoding="utf-8") as f:
            return json.load(f)
    return {
        "processed": [],
        "projects": [],
        "rejected": [],
        "failed": [],
        "lastIndex": -1,
        "startedAt": datetime.utcnow().isoformat() + "Z"
    }


def save_resume_state(state: dict):
    """Save checkpoint state"""
    with open("european_youth_scraper_resume.json", "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)


def save_projects(projects: List[OpportunityProject]):
    """Save accepted projects to JSON"""
    output = {
        "source": "European Youth Portal",
        "language": "en",
        "projectCount": len(projects),
        "projects": [asdict(p) for p in projects],
        "savedAt": datetime.utcnow().isoformat() + "Z"
    }
    with open("european_youth_projects.json", "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    print(f"✓ Saved {len(projects)} projects to european_youth_projects.json")


def save_rejected(rejected: List[ScrapeRejection]):
    """Save rejected records to JSON"""
    output = {
        "rejectionCount": len(rejected),
        "rejections": [asdict(r) for r in rejected],
        "savedAt": datetime.utcnow().isoformat() + "Z"
    }
    with open("european_youth_rejected_projects.json", "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    print(f"✓ Saved {len(rejected)} rejections to european_youth_rejected_projects.json")


def save_failed(failed: List[ScrapeFailed]):
    """Save failed URLs to JSON"""
    output = {
        "failureCount": len(failed),
        "failures": [asdict(f) for f in failed],
        "savedAt": datetime.utcnow().isoformat() + "Z"
    }
    with open("european_youth_failed_urls.json", "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    print(f"✓ Saved {len(failed)} failures to european_youth_failed_urls.json")


def scrape_opportunity(session: requests.Session, url: str) -> Tuple[Optional[OpportunityProject], str]:
    """Fetch and parse a single opportunity"""
    try:
        resp = session.get(url, timeout=20)
        resp.raise_for_status()
        resp.encoding = resp.apparent_encoding or "utf-8"
        
        proj, error = extract_project_data(resp.text, url)
        if error:
            return None, error
        
        if not proj:
            return None, "no_data_extracted"
        
        # Validate quality
        valid, reason = validate_project(proj)
        if not valid:
            return None, reason
        
        return proj, None
    
    except requests.RequestException as e:
        return None, f"request_error: {str(e)}"
    except Exception as e:
        return None, f"unexpected_error: {str(e)}"


def main():
    parser = argparse.ArgumentParser(description="European Youth Portal Opportunity Scraper")
    parser.add_argument("--limit", type=int, default=None, help="Process first N URLs")
    parser.add_argument("--resume", action="store_true", help="Resume from checkpoint")
    parser.add_argument("--delay", type=float, default=0.5, help="Delay between requests (seconds)")
    args = parser.parse_args()
    
    print("=" * 60)
    print("European Youth Portal Opportunity Scraper v3")
    print("=" * 60)
    print(f"Limit: {args.limit or 'unlimited'}")
    print(f"Delay: {args.delay}s per request")
    print(f"Resume: {args.resume}\n")
    
    # Load URLs
    urls = load_urls()
    print(f"Loaded {len(urls)} URLs from european_youth_project_urls.json")
    
    if args.limit:
        urls = urls[:args.limit]
        print(f"Limited to {len(urls)} URLs")
    
    # Load resume state if requested
    state = load_resume_state() if args.resume else {
        "processed": [],
        "projects": [],
        "rejected": [],
        "failed": [],
        "lastIndex": -1,
        "startedAt": datetime.utcnow().isoformat() + "Z"
    }
    
    last_index = state.get("lastIndex", -1)
    print(f"Starting from index {last_index + 1} of {len(urls)}\n")
    
    # Create session
    session = create_session()
    
    # Process URLs
    projects = [OpportunityProject(**p) if isinstance(p, dict) else p for p in state.get("projects", [])]
    rejected = [ScrapeRejection(**r) if isinstance(r, dict) else r for r in state.get("rejected", [])]
    failed = [ScrapeFailed(**f) if isinstance(f, dict) else f for f in state.get("failed", [])]
    
    try:
        for i, url in enumerate(urls[last_index + 1:], start=last_index + 1):
            proj, error = scrape_opportunity(session, url)
            
            if proj:
                projects.append(proj)
                print(f"[{i+1}/{len(urls)}] ✓ {proj.title[:60]}")
            elif error:
                rejected.append(ScrapeRejection(url=url, reason=error))
                print(f"[{i+1}/{len(urls)}] ✗ Rejected: {error}")
            else:
                failed.append(ScrapeFailed(url=url, error="unknown"))
                print(f"[{i+1}/{len(urls)}] ✗ Failed: unknown error")
            
            # Save checkpoint every 10 records
            if (i + 1) % 10 == 0:
                state = {
                    "processed": [asdict(p) for p in projects],
                    "projects": [asdict(p) for p in projects],
                    "rejected": [asdict(r) for r in rejected],
                    "failed": [asdict(f) for f in failed],
                    "lastIndex": i,
                    "startedAt": state.get("startedAt", datetime.utcnow().isoformat() + "Z")
                }
                save_resume_state(state)
            
            time.sleep(args.delay)
    
    finally:
        session.close()
    
    # Save results
    print("\n" + "=" * 60)
    print("SCRAPING COMPLETE")
    print("=" * 60)
    print(f"Total processed: {len(projects) + len(rejected) + len(failed)}")
    print(f"Accepted projects: {len(projects)}")
    print(f"Rejected records: {len(rejected)}")
    print(f"Failed URLs: {len(failed)}")
    
    save_projects(projects)
    save_rejected(rejected)
    save_failed(failed)
    
    # Clean up resume file
    resume_file = Path("european_youth_scraper_resume.json")
    if resume_file.exists():
        resume_file.unlink()
        print("Resume file cleaned (complete).")
    
    print("Done.")


if __name__ == "__main__":
    main()
