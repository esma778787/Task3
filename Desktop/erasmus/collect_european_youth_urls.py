"""
Collect all accessible English European Youth Portal opportunity URLs.
Handles pagination, load-more buttons, and infinite scroll.
Saves progress to JSON for resumability.
"""

import json
import time
from pathlib import Path
from urllib.parse import urlparse, parse_qs
from datetime import datetime

from playwright.sync_api import sync_playwright

LIST_PAGE = "https://youth.europa.eu/go-abroad/volunteering/opportunities_en"
OUTPUT_FILE = Path("european_youth_project_urls.json")

MAX_ITERATIONS = 100
NO_NEW_LINK_LIMIT = 3
SCROLL_PAUSE_TIME = 2.0
BUTTON_WAIT_TIME = 3000

# Load or init output structure
def load_or_init_urls():
    if OUTPUT_FILE.exists():
        try:
            data = json.loads(OUTPUT_FILE.read_text(encoding='utf-8'))
            print(f"Resuming: {len(data.get('project_urls', []))} URLs already collected.")
            return data
        except Exception as e:
            print(f"Error loading {OUTPUT_FILE.name}: {e}")
    
    return {
        "source": "European Youth Portal",
        "language": "en",
        "collectedAt": datetime.now().isoformat(),
        "projectCount": 0,
        "project_urls": [],
        "iterationLog": []
    }

def normalize_url(url: str) -> str:
    """Normalize and validate URL."""
    if not url or not isinstance(url, str):
        return None
    
    url = url.strip()
    
    # Ensure https and youth.europa.eu domain
    if url.startswith('//'):
        url = 'https:' + url
    elif url.startswith('/'):
        url = 'https://youth.europa.eu' + url
    elif not url.startswith('http'):
        url = 'https://youth.europa.eu' + url
    
    # Verify domain
    if 'youth.europa.eu' not in url:
        return None
    
    # Verify opportunity path
    if '/solidarity/opportunity/' not in url:
        return None
    
    # Ensure _en suffix for English
    parsed = urlparse(url)
    path = parsed.path
    
    if not path.endswith('_en'):
        # Try to extract project ID and add _en
        if '/solidarity/opportunity/' in path:
            parts = path.split('/solidarity/opportunity/')
            if len(parts) > 1:
                proj_id = parts[1].rstrip('/').split('?')[0].split('#')[0]
                if proj_id and not proj_id.endswith('_en'):
                    # If we can identify it's not _en, add it
                    if '_' not in proj_id or not proj_id.split('_')[-1].isalpha():
                        proj_id += '_en'
                url = f"https://youth.europa.eu/solidarity/opportunity/{proj_id}"
    
    # Remove fragment and unnecessary query params
    if '?' in url:
        url = url.split('?')[0]
    if '#' in url:
        url = url.split('#')[0]
    
    return url.rstrip('/')

def extract_opportunity_links(page) -> list:
    """Extract all opportunity links from current DOM state."""
    try:
        links = page.locator('a[href*="/solidarity/opportunity/"]').evaluate_all(
            "elements => elements.map(e => e.href).filter(Boolean)"
        )
        return links if links else []
    except Exception as e:
        print(f"  Error extracting links: {e}")
        return []

def find_load_more_button(page):
    """Find and return load-more or next page button."""
    selectors = [
        'button:has-text("Load more")',
        'button:has-text("Show more")',
        'button:has-text("Next")',
        'a:has-text("Next")',
        'a[rel="next"]',
        'button[aria-label*="next"]',
        'button[aria-label*="Next"]',
        'button[data-drupal-selector*="next"]',
        '.pager__item.pager__item--next a',
        '.pager a.active ~ a',
        '.pagination a.next',
    ]
    
    for selector in selectors:
        try:
            locator = page.locator(selector).first
            if locator.is_visible():
                return locator
        except Exception:
            pass
    
    return None

def scroll_page(page):
    """Scroll to bottom to trigger infinite scroll if present."""
    try:
        page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
    except Exception:
        pass

def collect_all_urls():
    """Main collection loop."""
    data = load_or_init_urls()
    collected_urls = set(data.get("project_urls", []))
    
    iteration = 0
    no_new_count = 0
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()
        
        print(f"\nNavigating to {LIST_PAGE}")
        page.goto(LIST_PAGE, wait_until="networkidle", timeout=60000)
        page.wait_for_timeout(2000)
        
        # Handle consent if present
        try:
            consent_btn = page.locator('button:has-text("Accept"), button:has-text("Agree")').first
            if consent_btn.is_visible():
                print("Accepting consent...")
                consent_btn.click()
                page.wait_for_timeout(1000)
        except Exception:
            pass
        
        while iteration < MAX_ITERATIONS:
            iteration += 1
            print(f"\n[Iteration {iteration}]")
            print(f"  Links before: {len(collected_urls)}")
            
            # Extract links from current DOM
            current_links = extract_opportunity_links(page)
            current_links = [normalize_url(l) for l in current_links if l]
            current_links = [l for l in current_links if l]
            
            # Count new links
            new_links = [l for l in current_links if l not in collected_urls]
            print(f"  Links after: {len(current_links)}")
            print(f"  New links: {len(new_links)}")
            
            # Add to collection
            collected_urls.update(new_links)
            
            # Check stop condition
            if not new_links:
                no_new_count += 1
                print(f"  No new links (count: {no_new_count})")
                
                if no_new_count >= NO_NEW_LINK_LIMIT:
                    print(f"  Stopping: {NO_NEW_LINK_LIMIT} iterations with no new links.")
                    break
            else:
                no_new_count = 0
            
            # Try to find and click load-more or next button
            action_used = None
            load_more_btn = find_load_more_button(page)
            
            if load_more_btn:
                try:
                    print("  Action: Clicking load-more/next button")
                    action_used = "button_click"
                    load_more_btn.click()
                    page.wait_for_timeout(BUTTON_WAIT_TIME)
                except Exception as e:
                    print(f"  Error clicking button: {e}")
                    action_used = "button_click_failed"
            else:
                # Try scrolling for infinite scroll
                print("  Action: Scrolling to bottom")
                action_used = "scroll"
                scroll_page(page)
                page.wait_for_timeout(SCROLL_PAUSE_TIME * 1000)
            
            # Log iteration
            data["iterationLog"].append({
                "iteration": iteration,
                "links_before": len(collected_urls) - len(new_links),
                "links_after": len(collected_urls),
                "new_links_this_round": len(new_links),
                "action": action_used or "none"
            })
            
            # Save progress
            data["projectCount"] = len(collected_urls)
            data["project_urls"] = sorted(list(collected_urls))
            data["collectedAt"] = datetime.now().isoformat()
            
            OUTPUT_FILE.write_text(
                json.dumps(data, ensure_ascii=False, indent=2),
                encoding='utf-8'
            )
        
        browser.close()
    
    return data

if __name__ == "__main__":
    print("="*60)
    print("European Youth Portal URL Collector")
    print("="*60)
    
    result = collect_all_urls()
    
    print("\n" + "="*60)
    print("COLLECTION COMPLETE")
    print("="*60)
    print(f"Total unique English opportunity URLs: {result['projectCount']}")
    print(f"Iterations completed: {len(result['iterationLog'])}")
    
    if result['iterationLog']:
        last_log = result['iterationLog'][-1]
        print(f"Stop reason: {last_log['action']} (Iteration {last_log['iteration']})")
    
    print(f"Output file: {OUTPUT_FILE.name}")
    print(f"First 5 URLs:")
    for url in result['project_urls'][:5]:
        print(f"  {url}")
    
    print("\nDone.")
