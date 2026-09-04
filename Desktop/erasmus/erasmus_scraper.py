from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import time
from datetime import datetime
from bs4 import BeautifulSoup
from pymongo import MongoClient
from flask import Flask, jsonify
from flask_cors import CORS

DETAIL_LIMIT = None
DETAIL_DELAY = 2

# ---------------- A. MongoDB Bağlantısı (tek seferlik) ---------------- #
client = MongoClient("mongodb://localhost:27017/")
db = client["erasmus_db"]
collection = db["erasmusgram_projects"]

# ---------------- B. VERİ ÇEKME (İlk 25 sayfa) ---------------- #
def scrape_erasmusgram():
    options = Options()
    # options.add_argument("--headless")  # Arka planda çalıştırmak istersen aktif et
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--ignore-certificate-errors")

    driver = webdriver.Chrome(options=options)

    base_url = "https://www.erasmusgram.com/category/avrupa-birligi-projeleri/kisa-donem-gonulluluk-projeleri/"
    projects = []

    for page in range(1, 26):
        print(f"\n📄 Sayfa {page} taranıyor...")
        url = f"{base_url}page/{page}/" if page > 1 else base_url
        driver.get(url)
        time.sleep(5)

        soup = BeautifulSoup(driver.page_source, "html.parser")
        articles = soup.find_all("article")
        print(f"🔍 {len(articles)} proje bulundu.")

        if not articles:
            print("❌ Bu sayfa boş. Tarama durduruldu.")
            break

        for article in articles:
            link = article.find("a")
            title = link.get("title") if link else "Başlık yok"
            href = link.get("href") if link else "Link yok"
            projects.append({"title": title, "link": href})

    driver.quit()
    return projects

# ---------------- B.1. Detay Sayfası Çekme ---------------- #
def create_webdriver():
    options = Options()
    # options.add_argument("--headless")  # Arka planda çalıştırmak istersen aktif et
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--ignore-certificate-errors")
    return webdriver.Chrome(options=options)


def normalize_text(value):
    return value.strip() if isinstance(value, str) else ""


def remove_unwanted_elements(node):
    if not node:
        return

    selectors = [
        "header",
        "footer",
        "nav",
        "aside",
        "form",
        ".sidebar",
        ".widget",
        ".cookie",
        ".cookies",
        ".cookie-banner",
        "script",
        "style",
        "noscript",
        "iframe",
        "button",
    ]

    for selector in selectors:
        for unwanted in node.select(selector):
            unwanted.decompose()


def extract_content(soup):
    selectors = [
        "div.td-post-content",
        "div.entry-content",
        "div.post-content",
        "article .entry-content",
        "main article",
        "article",
    ]

    best_text = ""
    best_selector = None

    for selector in selectors:
        node = soup.select_one(selector)
        if not node:
            continue

        remove_unwanted_elements(node)
        text = node.get_text(" ", strip=True)

        if len(text) >= 300:
            return text, selector

        if len(text) > len(best_text):
            best_text = text
            best_selector = selector

    body = soup.body
    if body:
        remove_unwanted_elements(body)
        body_text = body.get_text(" ", strip=True)
        if len(body_text) >= 300:
            return body_text, "body"
        if len(body_text) > len(best_text):
            best_text = body_text
            best_selector = "body"

    return best_text, best_selector


def parse_line_value(line):
    separators = [":", " – ", " - ", " — ", " | "]

    for sep in separators:
        if sep in line:
            parts = line.split(sep, 1)
            if len(parts) > 1:
                return parts[1].strip()
    return ""


def extract_metadata(soup):
    page_text = soup.get_text("\n", strip=True)
    lines = [line.strip() for line in page_text.splitlines() if line.strip()]

    result = {
        "location": "",
        "ageRange": "",
        "startDate": "",
        "endDate": "",
    }

    keywords = {
        "location": ["location", "yer", "konum", "ülke", "şehir", "ülkesi", "city"],
        "ageRange": ["age range", "age", "yaş", "yas aralığı", "yas araligi", "age group"],
        "startDate": ["start date", "start", "başlangıç", "başlangic", "başlangıç tarihi", "başlangic tarihi"],
        "endDate": ["end date", "end", "bitiş", "bitis", "bitiş tarihi", "bitis tarihi", "finish"],
    }

    for index, line in enumerate(lines):
        lower_line = line.lower()

        for field, keys in keywords.items():
            if result[field]:
                continue

            if any(key in lower_line for key in keys):
                value = parse_line_value(line)
                if not value and index + 1 < len(lines):
                    next_line = lines[index + 1]
                    if next_line and not any(key in next_line.lower() for key in keys):
                        value = next_line.strip()

                if value:
                    result[field] = normalize_text(value)

        if all(result.values()):
            break

    return result


# ---------------- C. Flask API ---------------- #
app = Flask(__name__)
CORS(app)

@app.route("/erasmusgram", methods=["GET"])
def get_projects():
    projects = list(collection.find({}, {"_id": 0}).limit(200))
    return jsonify(projects)


# ---------------- D. Ana Akış ---------------- #
def enrich_existing_projects():
    documents = list(collection.find({}, {"_id": 0, "link": 1, "title": 1}))
    total_records = len(documents)
    print(f"📦 Toplam kayıt: {total_records}")

    if DETAIL_LIMIT is not None:
        documents = documents[:DETAIL_LIMIT]

    driver = create_webdriver()
    updated_count = 0
    failed_count = 0

    for index, document in enumerate(documents, start=1):
        title = document.get("title", "Başlık yok")
        link = document.get("link")
        print(f"[{index}/{total_records}] {title}")

        if not link or not isinstance(link, str) or not link.startswith("http"):
            print("  ❌ Geçersiz link, atlandı.")
            failed_count += 1
            continue

        try:
            driver.get(link)
            time.sleep(DETAIL_DELAY)

            soup = BeautifulSoup(driver.page_source, "html.parser")
            content, selector = extract_content(soup)
            content = content or ""
            metadata = extract_metadata(soup)

            print(f"  title: {title}")
            print(f"  link: {link}")
            print(f"  selector: {selector or 'none'}")
            print(f"  extracted content length: {len(content)}")
            if len(content) < 300:
                print("  ⚠️ SHORT_CONTENT")

            update_fields = {
                "content": content,
                "description": content,
                "sdescription": content,
                "contentLength": len(content),
                "descriptionLength": len(content),
                "location": metadata.get("location", ""),
                "ageRange": metadata.get("ageRange", ""),
                "startDate": metadata.get("startDate", ""),
                "endDate": metadata.get("endDate", ""),
                "source": document.get("source", ""),
                "scrapedAt": datetime.utcnow(),
            }

            result = collection.update_one({"link": link}, {"$set": update_fields}, upsert=False)
            if result.matched_count:
                updated_count += 1
                print("  ✅ Güncellendi.")
            else:
                failed_count += 1
                print("  ⚠️ Kayıt bulunamadı, güncellenmedi.")
        except Exception as exc:
            failed_count += 1
            print(f"  ❌ Detay sayfası işlenirken hata: {exc}")

    driver.quit()
    print(f"✅ Güncellenen: {updated_count}, ❌ Başarısız: {failed_count}")


def debug_description_content_lengths(limit=10):
    print("\n🔧 Debug: İlk 10 kaydın description/content uzunlukları")

    cursor = collection.find(
        {},
        {"_id": 0, "title": 1, "link": 1, "description": 1, "content": 1},
    ).limit(limit)

    for index, doc in enumerate(cursor, start=1):
        desc_len = len(doc.get("description", "") or "")
        content_len = len(doc.get("content", "") or "")
        print(
            f"[{index}] title={doc.get('title','')[:80]} | link={doc.get('link','')} | description={desc_len} | content={content_len}"
        )


if __name__ == "__main__":
    enrich_existing_projects()
    debug_description_content_lengths()
