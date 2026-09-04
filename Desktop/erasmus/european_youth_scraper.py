import json
import re
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import requests
from bs4 import BeautifulSoup
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

BASE_URL = "https://youth.europa.eu"
LIST_PAGE = "https://youth.europa.eu/go-abroad/volunteering/opportunities_en"
USER_AGENT = "ErasmusSimulationAcademicProject/1.0"
OUTPUT_FILE = Path("european_youth_projects.json")
ERROR_FILE = Path("european_youth_scraper_errors.json")
URL_CACHE_FILE = Path("european_youth_project_urls.json")


@dataclass
class ScrapeError:
    url: str
    error: str


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


def normalize_url(url: str) -> str:
    if url.startswith("//"):
        return f"https:{url}"
    if url.startswith("/"):
        return f"{BASE_URL.rstrip('/')}{url}"
    return url


def get_page(session: requests.Session, url: str) -> Tuple[str, Optional[str]]:
    response = session.get(url, timeout=20)
    response.raise_for_status()
    response.encoding = response.apparent_encoding or "utf-8"
    return response.text, response.encoding


def extract_script_candidates(html: str, base_url: str) -> List[str]:
    soup = BeautifulSoup(html, "html.parser")
    scripts = []
    for script in soup.find_all("script"):
        src = script.get("src")
        if src:
            scripts.append(normalize_url(src))
    return scripts


def find_endpoint_candidates(html: str) -> List[str]:
    patterns = [
        r"https?://[^\s\"\']*(?:json|api|view|opportunity|ajax)[^\s\"\']*",
        r"/[^\s\"\']*(?:json|api|view|opportunity|ajax)[^\s\"\']*",
    ]
    candidates: List[str] = []
    for pat in patterns:
        for match in re.findall(pat, html):
            if match not in candidates:
                candidates.append(match)
    return candidates


def inspect_list_page() -> None:
    session = create_session()
    html, encoding = get_page(session, LIST_PAGE)
    print(f"Fetched list page ({LIST_PAGE}) with encoding={encoding}")
    script_urls = extract_script_candidates(html, BASE_URL)
    print(f"Found {len(script_urls)} script src URLs")
    for src in script_urls:
        print(f"  SCRIPT: {src}")
    candidate_urls = find_endpoint_candidates(html)
    print(f"Found {len(candidate_urls)} candidate endpoint strings in HTML")
    for candidate in candidate_urls[:50]:
        print(f"  CAND: {candidate}")
    soup = BeautifulSoup(html, "html.parser")
    json_tag_count = len(soup.select('script[type="application/json"]'))
    print(f"Found {json_tag_count} application/json script tags")
    if json_tag_count:
        for i, tag in enumerate(soup.select('script[type="application/json"]'), start=1):
            data = tag.string or ""
            print(f"JSON TAG {i} len={len(data)}")
            snippet = data[:500].replace("\n", " ")
            print(snippet)
            print("---")
    forms = soup.find_all('form')
    print(f"Found {len(forms)} form elements")
    for idx, form in enumerate(forms[:10], start=1):
        print(f"FORM {idx}: id={form.get('id')} action={form.get('action')} method={form.get('method')} class={form.get('class')}")
        inputs = form.find_all('input')
        for inp in inputs[:20]:
            print(f"  INPUT name={inp.get('name')} value={inp.get('value')}")
        print('---')
    ajax_forms = soup.select('[data-ajax-form], [data-drupal-selector]')
    print(f"Found {len(ajax_forms)} ajax-related markers")
    for idx, tag in enumerate(ajax_forms[:20], start=1):
        print(f"TAG {idx}: {tag.name} attrs={tag.attrs}")

    inspect_ajax_form(html, soup)


def inspect_ajax_form(html: str, soup: BeautifulSoup) -> None:
    ajax_urls = []
    if 'ajax_form=1' in html:
        ajax_urls.append(LIST_PAGE + '?ajax_form=1')
    form = soup.find('form', attrs={'id': 'user-input-feedback-form'})
    if form:
        action = form.get('action')
        if action and 'ajax_form=1' in action:
            ajax_urls.append(normalize_url(action))
    print(f"Inspecting {len(ajax_urls)} ajax_form endpoints")
    session = create_session()
    for url in ajax_urls:
        try:
            print(f"Fetching AJAX endpoint: {url}")
            response = session.get(url, timeout=20)
            print('AJAX status', response.status_code)
            print('AJAX content starts', response.text[:800].replace('\n', ' '))
        except Exception as e:
            print(f"AJAX endpoint error {url}: {e}")


def main() -> None:
    inspect_list_page()


if __name__ == "__main__":
    main()
