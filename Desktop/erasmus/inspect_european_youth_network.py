import json
import re
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urljoin, urlparse, parse_qs

from playwright.sync_api import sync_playwright

LIST_PAGE = "https://youth.europa.eu/go-abroad/volunteering/opportunities_en"
FILTER_KEYWORDS = ["opportunity", "volunteering", "solidarity", "ajax", "views", "project"]
ALLOWED_RESOURCE_TYPES = {"xhr", "fetch", "document"}
IGNORED_RESOURCE_TYPES = {"image", "font", "stylesheet", "media"}
CANDIDATE_FIELDS = {
    "id",
    "title",
    "name",
    "town",
    "country",
    "duration",
    "date_start",
    "date_end",
    "date_application_end",
    "deadline",
    "organisation",
    "description",
    "is_esc_related",
}
MAX_DISPLAY_LINKS = 5
RESPONSE_JSON_PATH = Path("candidate_opportunity_response.json")
RESPONSE_HTML_PATH = Path("candidate_opportunity_response.html")
ENDPOINT_PATH = Path("candidate_opportunity_endpoint.json")


def normalize_link(base: str, href: str) -> str:
    return urljoin(base, href)


def extract_links_from_html(html: str, base_url: str) -> list[str]:
    links = []

    class LinkParser(HTMLParser):
        def handle_starttag(self, tag, attrs):
            if tag.lower() != "a":
                return
            attrs_dict = {name.lower(): value for name, value in attrs}
            href = attrs_dict.get("href")
            if not href:
                return
            href = href.strip()
            if "/solidarity/opportunity/" in href or "opportunity-" in href:
                links.append(normalize_link(base_url, href))

    parser = LinkParser()
    parser.feed(html)
    return list(dict.fromkeys(links))


def extract_links_from_text(text: str, base_url: str) -> list[str]:
    links = []
    for match in re.findall(r'"(/solidarity/opportunity/[\w\-]+_en)"', text):
        links.append(normalize_link(base_url, match))
    for match in re.findall(r'"(https?://[^"\']*/solidarity/opportunity/[\w\-]+_en)"', text):
        links.append(match)
    for match in re.findall(r'/solidarity/opportunity/[\w\-]+_en', text):
        links.append(normalize_link(base_url, match))
    return list(dict.fromkeys(links))


def find_candidate_dicts(node):
    found = []

    def _walk(value):
        if isinstance(value, dict):
            if len(CANDIDATE_FIELDS.intersection(value.keys())) >= 3:
                found.append(value)
            for key, subvalue in value.items():
                if isinstance(subvalue, (dict, list)):
                    _walk(subvalue)
        elif isinstance(value, list):
            for item in value:
                _walk(item)

    _walk(node)
    return found


def is_drupal_ajax_response(data) -> bool:
    if isinstance(data, list):
        return any(isinstance(item, dict) and "command" in item and "data" in item for item in data)
    return False


def extract_html_from_drupal_ajax(data) -> list[str]:
    links = []
    if isinstance(data, list):
        for item in data:
            if not isinstance(item, dict):
                continue
            if item.get("command") in {"insert", "replace", "append", "prepend"} and item.get("data"):
                html = item["data"]
                links.extend(extract_links_from_html(html, LIST_PAGE))
    return list(dict.fromkeys(links))


def summarize_json_response(data) -> dict:
    top_type = "list" if isinstance(data, list) else "object" if isinstance(data, dict) else type(data).__name__
    top_keys = list(data.keys()) if isinstance(data, dict) else []
    candidate_records = find_candidate_dicts(data)
    sample_keys = []
    if candidate_records:
        sample_keys = [list(rec.keys()) for rec in candidate_records[:3]]
    return {
        "top_level_type": top_type,
        "top_level_keys": top_keys,
        "possible_record_count": len(candidate_records),
        "sample_record_keys": sample_keys,
        "has_id": any("id" in rec for rec in candidate_records),
        "has_title": any("title" in rec or "name" in rec for rec in candidate_records),
        "has_country": any("country" in rec for rec in candidate_records),
        "has_description": any("description" in rec for rec in candidate_records),
    }


def parse_json_body(text: str):
    try:
        return json.loads(text)
    except Exception:
        return None


def sanitize_request_headers(request_headers: dict) -> dict:
    keys = ["content-type", "x-requested-with"]
    return {k: v for k, v in request_headers.items() if k.lower() in keys}


def save_candidate_response(response, data, is_json: bool):
    if is_json:
        try:
            with RESPONSE_JSON_PATH.open("w", encoding="utf-8") as out:
                json.dump(data, out, ensure_ascii=False, indent=2)
            return RESPONSE_JSON_PATH.name
        except Exception:
            pass
    try:
        body_text = response.body().decode("utf-8", errors="replace")
    except Exception:
        body_text = ""
    with RESPONSE_HTML_PATH.open("w", encoding="utf-8") as out:
        out.write(body_text)
    return RESPONSE_HTML_PATH.name


def collect_candidate_endpoint(response, record_count, exposure):
    request = response.request
    url = request.url
    method = request.method
    content_type = response.headers.get("content-type", "")
    query_params = parse_qs(urlparse(url).query)
    post_data = None
    try:
        post_data = request.post_data
    except Exception:
        post_data = None
    data = {
        "url": url,
        "method": method,
        "contentType": content_type,
        "status": response.status,
        "queryParams": query_params,
        "postData": post_data,
        "recordCount": record_count,
        "candidateType": exposure,
    }
    with ENDPOINT_PATH.open("w", encoding="utf-8") as out:
        json.dump(data, out, ensure_ascii=False, indent=2)
    return data


def response_is_candidate(response):
    request = response.request
    rtype = request.resource_type
    if rtype in IGNORED_RESOURCE_TYPES:
        return False
    if rtype not in ALLOWED_RESOURCE_TYPES:
        return False

    headers = response.headers
    content_type = headers.get("content-type", "")
    body_bytes = b""
    try:
        body_bytes = response.body()
    except Exception:
        return False
    text = body_bytes.decode("utf-8", errors="replace")

    if any(ct in content_type for ct in ["application/json", "application/vnd.api+json", "text/json"]):
        data = parse_json_body(text)
        if data is None:
            return False
        summary = summarize_json_response(data)
        return summary["possible_record_count"] > 0

    if "text/html" in content_type or is_drupal_ajax_response(parse_json_body(text) or []):
        lower = text.lower()
        return any(marker in lower for marker in [
            "solidarity/opportunity",
            "opportunity-",
            "views-row",
            "view-content",
            "pager",
            "load-more",
        ])
    return False


def inspect_response(response):
    request = response.request
    resource_type = request.resource_type
    url = request.url
    status = response.status
    content_type = response.headers.get("content-type", "")
    body_bytes = b""
    try:
        body_bytes = response.body()
    except Exception:
        pass
    text = body_bytes.decode("utf-8", errors="replace")

    summary = {
        "url": url,
        "method": request.method,
        "status": status,
        "content_type": content_type,
        "response_length": len(body_bytes),
        "resource_type": resource_type,
        "query_params": parse_qs(urlparse(url).query),
    }

    json_data = None
    json_summary = None
    html_links = []
    drupal_links = []
    if any(ct in content_type for ct in ["application/json", "application/vnd.api+json", "text/json"]):
        json_data = parse_json_body(text)
        if json_data is not None:
            json_summary = summarize_json_response(json_data)
            if is_drupal_ajax_response(json_data):
                drupal_links = extract_html_from_drupal_ajax(json_data)
    elif "text/html" in content_type:
        html_links = extract_links_from_html(text, LIST_PAGE)

    # If HTML fragment exists in JSON array as raw data field
    if json_data is not None and not drupal_links and not html_links:
        drupal_links = extract_html_from_drupal_ajax(json_data)

    summary.update({
        "json_summary": json_summary,
        "html_links": html_links,
        "drupal_links": drupal_links,
    })
    return summary


if __name__ == "__main__":
    inspected = []
    candidates = []
    json_candidates = []
    drupal_candidates = []
    html_candidates = []
    opportunity_links_network = set()
    best_candidate = None
    best_candidate_response = None
    saved_response_file = None

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()

        def record_response(response):
            request = response.request
            resource_type = request.resource_type
            if resource_type in IGNORED_RESOURCE_TYPES:
                return
            if resource_type not in ALLOWED_RESOURCE_TYPES:
                return
            url_lower = request.url.lower()
            if any(keyword in url_lower for keyword in FILTER_KEYWORDS):
                inspected.append(response)

        page.on("response", record_response)

        print("Navigating to list page and waiting for network idle...")
        page.goto(LIST_PAGE, wait_until="networkidle", timeout=60000)
        page.wait_for_timeout(2000)

        print(f"Captured {len(inspected)} network responses to inspect.")

        for response in inspected:
            summary = inspect_response(response)
            if not response_is_candidate(response):
                continue

            candidates.append((summary, response))
            content_type = summary["content_type"].lower()
            if any(ct in content_type for ct in ["application/json", "application/vnd.api+json", "text/json"]):
                json_candidates.append(summary)
            if summary["drupal_links"]:
                drupal_candidates.append(summary)
            if summary["html_links"]:
                html_candidates.append(summary)

            print("\nCandidate response:")
            print("  url:", summary["url"])
            print("  status:", summary["status"])
            print("  content_type:", summary["content_type"])
            if summary["json_summary"]:
                print("  json_summary:", summary["json_summary"])
            if summary["html_links"]:
                print("  html_links:", summary["html_links"])
            if summary["drupal_links"]:
                print("  drupal_links:", summary["drupal_links"])

        def candidate_score(summary):
            if summary["json_summary"]:
                type_score = 2
            elif summary["drupal_links"]:
                type_score = 1
            else:
                type_score = 0
            record_count = summary["json_summary"]["possible_record_count"] if summary["json_summary"] else len(summary["html_links"]) + len(summary["drupal_links"])
            return (type_score, record_count)

        if candidates:
            best_summary, best_response = max(candidates, key=lambda item: candidate_score(item[0]))
            best_candidate = best_summary
            best_candidate_response = best_response
            content_type = best_summary["content_type"].lower()
            data = None
            if content_type.startswith("application/json"):
                try:
                    data = parse_json_body(best_response.body().decode("utf-8", errors="replace"))
                except Exception:
                    data = None
            saved_response_file = save_candidate_response(best_response, data, data is not None)
            best_candidate = collect_candidate_endpoint(
                best_response,
                best_summary["json_summary"]["possible_record_count"] if best_summary["json_summary"] else len(best_summary["html_links"]) + len(best_summary["drupal_links"]),
                "json" if best_summary["json_summary"] else ("drupal" if best_summary["drupal_links"] else "html"),
            )
            if best_summary["html_links"]:
                opportunity_links_network.update(best_summary["html_links"])
            opportunity_links_network.update(best_summary["drupal_links"])
            if data is None:
                opportunity_links_network.update(extract_links_from_text(best_response.body().decode("utf-8", errors="replace"), LIST_PAGE))

        print("\n--- Candidate Response Summary ---")
        print("XHR/FETCH responses inspected:", len(inspected))
        print("JSON candidate responses:", len(json_candidates))
        print("Drupal AJAX candidate responses:", len(drupal_candidates))
        print("HTML candidate responses:", len(html_candidates))
        print("Opportunity links found in network:", len(opportunity_links_network))

        dom_links = []
        try:
            dom_links = page.locator('a[href*="/solidarity/opportunity/"]').evaluate_all(
                "elements => elements.map(e => e.href).filter(Boolean)"
            )
        except Exception:
            dom_links = []

        dom_links = list(dict.fromkeys(dom_links))
        print("Opportunity links found in DOM:", len(dom_links))
        if dom_links:
            for link in dom_links[:MAX_DISPLAY_LINKS]:
                print("  ", link)

        page_content = page.content()
        found_page_markers = {marker: marker in page_content for marker in ["date_start", "date_application_end", "is_esc_related"]}
        print("Page content markers:", found_page_markers)

        consent_buttons = page.locator('button:has-text("Accept"), button:has-text("Agree"), button:has-text("Continue")')
        try:
            consent_count = consent_buttons.count()
        except Exception:
            consent_count = 0
        print("Consent button candidates found:", consent_count)

        if best_candidate:
            print("Best candidate endpoint:", best_candidate["url"])
            print("Candidate response saved:", saved_response_file)
        else:
            print("Best candidate endpoint: None")
            print("Candidate response saved: None")

        browser.close()
