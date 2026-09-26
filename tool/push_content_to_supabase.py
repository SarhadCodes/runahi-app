#!/usr/bin/env python3
"""Push current app content into the linked hosted Supabase project."""

from __future__ import annotations

import json
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IMANI = Path.home() / "AppData/Local/Pub/Cache/hosted/pub.dev/imanikurd-1.1.1/assets/data"
REF = (ROOT / "supabase/.temp/project-ref").read_text(encoding="utf-8").strip()
URL = f"https://{REF}.supabase.co"


def as_int(value) -> int:
    if isinstance(value, str):
        return int(float(value))
    return int(value)


def loc(sorani: str, badini: str | None = None) -> dict[str, str]:
    text = sorani or ""
    return {"sorani": text, "badini": badini if badini is not None else text}


def flatten_columns(rows: list[dict]) -> list[dict]:
    flattened: list[dict] = []
    for row in rows:
        item: dict = {}
        for key, value in row.items():
            if isinstance(value, dict) and ("sorani" in value or "badini" in value):
                item[f"{key}_sorani"] = value.get("sorani") or ""
                item[f"{key}_badini"] = value.get("badini") or value.get("sorani") or ""
            elif (
                isinstance(value, list)
                and value
                and isinstance(value[0], dict)
                and ("sorani" in value[0] or "badini" in value[0])
            ):
                item[f"{key}_sorani"] = [part.get("sorani") or "" for part in value]
                item[f"{key}_badini"] = [part.get("badini") or part.get("sorani") or "" for part in value]
            else:
                item[key] = value
        flattened.append(item)
    return flattened


def load(name: str):
    return json.loads((IMANI / name).read_text(encoding="utf-8"))


def service_role_key() -> str:
    raw = subprocess.check_output(
        f"npx supabase projects api-keys --project-ref {REF}",
        cwd=ROOT,
        shell=True,
        text=True,
        encoding="utf-8",
        stderr=subprocess.DEVNULL,
    )
    payload = json.loads(raw[raw.find("{") :])
    for item in payload.get("keys", []):
        if item.get("name") == "service_role" or item.get("id") == "service_role":
            return item["api_key"]
    raise SystemExit("service_role key not found")


def upsert(table: str, rows: list[dict], key: str, batch: int = 80) -> None:
    rows = flatten_columns(rows)
    if not rows:
        return
    for start in range(0, len(rows), batch):
        chunk = rows[start : start + batch]
        data = json.dumps(chunk).encode("utf-8")
        conflict = "number" if table == "surahs" else "id"
        request = urllib.request.Request(
            f"{URL}/rest/v1/{table}?on_conflict={conflict}",
            data=data,
            method="POST",
            headers={
                "apikey": key,
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json",
                "Prefer": "resolution=merge-duplicates,return=minimal",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                response.read()
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", errors="replace")
            raise SystemExit(f"{table} batch {start}: {error.code} {detail[:500]}") from error
        print(f"  {table}: {min(start + len(chunk), len(rows))}/{len(rows)}")


def tafsir_map(name: str) -> dict[tuple[int, int], str]:
    mapped: dict[tuple[int, int], str] = {}
    for entry in load(name):
        mapped[(as_int(entry["s"]), as_int(entry["a"]))] = str(entry.get("t") or "")
    return mapped


def main() -> None:
    if not IMANI.exists():
        raise SystemExit(f"imanikurd data not found: {IMANI}")
    key = service_role_key()
    quran = load("quran.json")
    library = load("library.json")
    hadiths = load("hadiths.json")
    names = load("names_of_allah.json")
    companions = load("companions.json")
    dhikr = load("dhikr.json")
    seerah = load("seerah.json")
    sorani = tafsir_map("tafsir_rebar.json")
    badini = tafsir_map("tafsir_runahi.json")

    surahs = [
        {
            "number": as_int(item["number"]),
            "name_arabic": item.get("name") or "",
            "name": loc(item.get("kurdishName") or item.get("englishName") or item.get("name") or ""),
            "ayah_count": as_int(item.get("numberOfAyahs") or 0),
        }
        for item in quran["surahs"]
    ]
    print("surahs")
    upsert("surahs", surahs, key, batch=114)

    verses = []
    surah_by_number = {item["number"]: item for item in quran["surahs"]}
    for ayah in quran["ayahs"]:
        surah_no = as_int(ayah["surah"])
        ayah_no = as_int(ayah["ayah"])
        meaning = loc(sorani.get((surah_no, ayah_no), ""), badini.get((surah_no, ayah_no), "") or None)
        if not meaning["badini"]:
            meaning["badini"] = meaning["sorani"]
        if not meaning["sorani"]:
            meaning["sorani"] = meaning["badini"]
        verses.append(
            {
                "id": f"{surah_no}-{ayah_no}",
                "surah_number": surah_no,
                "ayah_number": ayah_no,
                "arabic": ayah.get("text") or "",
                "translation": meaning,
                "explanation": meaning,
                "tafsir": meaning,
                "source_refs": [
                    loc("تەفسیری ڕێبەر · ئیمانی کورد", "تەفسیری ڕوناهی · ئیمانی کورد"),
                ],
                "related_verse_ids": [
                    *( [f"{surah_no}-{ayah_no - 1}"] if ayah_no > 1 else [] ),
                    *(
                        [f"{surah_no}-{ayah_no + 1}"]
                        if ayah_no < as_int(surah_by_number[surah_no].get("numberOfAyahs") or 0)
                        else []
                    ),
                ],
                "word_ids": [],
                "audio_url": ayah.get("audioLink"),
            }
        )
    print("verses")
    upsert("verses", verses, key, batch=40)

    words = [
        {
            "id": f"name-{as_int(item['id'])}",
            "arabic": item.get("arabic") or "",
            "normalized": (item.get("english") or "").lower(),
            "root": item.get("english") or "",
            "meaning": loc(item.get("kurdish") or ""),
            "occurrences": 1,
            "surahs": [],
            "example_verse_ids": [],
            "related_word_ids": [],
        }
        for item in names
    ]
    words.extend(
        [
            {
                "id": "word-rahma",
                "arabic": "رَحْمَة",
                "normalized": "رحمة",
                "root": "ر-ح-م",
                "meaning": loc("بەزەیی / میهرەبانی", "دلۆڤانی / میهرەبانی"),
                "occurrences": 114,
                "surahs": [loc("فاتیحە"), loc("بەقەرە"), loc("ئەنعام")],
                "example_verse_ids": ["1-1"],
                "related_word_ids": ["word-ilm"],
            },
            {
                "id": "word-ilm",
                "arabic": "عِلْم",
                "normalized": "علم",
                "root": "ع-ل-م",
                "meaning": loc("زانست / زانیاری", "زانست / زانین"),
                "occurrences": 105,
                "surahs": [loc("تاها"), loc("عەلەق"), loc("بەقەرە")],
                "example_verse_ids": ["20-114", "96-1"],
                "related_word_ids": ["word-rahma"],
            },
            {
                "id": "word-sabr",
                "arabic": "صَبْر",
                "normalized": "صبر",
                "root": "ص-ب-ر",
                "meaning": loc("خۆگری / سەبر", "خۆگری / سەبر"),
                "occurrences": 103,
                "surahs": [loc("بەقەرە"), loc("عەسر")],
                "example_verse_ids": ["2-153"],
                "related_word_ids": ["word-salah"],
            },
            {
                "id": "word-salah",
                "arabic": "صَلَاة",
                "normalized": "صلاة",
                "root": "ص-ل-و",
                "meaning": loc("نوێژ", "نوێژ"),
                "occurrences": 99,
                "surahs": [loc("بەقەرە"), loc("موئمینوون")],
                "example_verse_ids": ["2-153"],
                "related_word_ids": ["word-sabr"],
            },
            {
                "id": "word-nur",
                "arabic": "نُور",
                "normalized": "نور",
                "root": "ن-و-ر",
                "meaning": loc("ڕووناکی / ڕووناهی", "ڕووناهی"),
                "occurrences": 43,
                "surahs": [loc("نوور"), loc("بەقەرە")],
                "example_verse_ids": ["20-114"],
                "related_word_ids": ["word-ilm"],
            },
            {
                "id": "word-iman",
                "arabic": "إِيمَان",
                "normalized": "ايمان",
                "root": "ء-م-ن",
                "meaning": loc("باوەڕ / ئیمان", "باوەڕ / ئیمان"),
                "occurrences": 45,
                "surahs": [loc("بەقەرە"), loc("ئیمان")],
                "example_verse_ids": ["2-153"],
                "related_word_ids": ["word-sabr"],
            },
        ]
    )
    print("words")
    upsert("words", words, key)

    hadith_chapters = [
        {
            "id": f"hadith-ch-{as_int(item['id'])}",
            "title": loc(item.get("title") or ""),
            "body": loc("\n\n".join(part for part in [item.get("arabic") or "", item.get("kurdish") or ""] if part.strip())),
            "sort_order": index + 2,
        }
        for index, item in enumerate(hadiths)
    ]

    books = []
    chapters = []

    def add_library(prefix: str, item: dict, title: str) -> None:
        book_id = f"{prefix}{as_int(item['id'])}"
        author = item.get("author") or ""
        description = item.get("description") or title
        category = item.get("category") or item.get("nameEn") or "کتێبخانەی ئیمانی کورد"
        books.append(
            {
                "id": book_id,
                "title": loc(title),
                "author": loc(author),
                "category": loc(category),
                "description": loc(description),
                "source_url": item.get("url") or item.get("downloadUrl"),
            }
        )
        if "ریاض" in title:
            for chapter in hadith_chapters:
                chapters.append({**chapter, "id": f"{book_id}-{chapter['id']}", "book_id": book_id})
        else:
            pages = item.get("pages")
            body = "\n\n".join(part for part in [description, author, f"{pages} لاپەڕە" if pages else ""] if part)
            chapters.append(
                {
                    "id": f"{book_id}-about",
                    "book_id": book_id,
                    "title": loc(title),
                    "body": loc(body),
                    "sort_order": 1,
                }
            )

    for item in library.get("books") or []:
        add_library("book-", item, item.get("title") or "")
        if any(book["id"].startswith("book-") for book in books):
            break
    books = books[:1]
    chapters = [chapter for chapter in chapters if books and chapter["book_id"] == books[0]["id"]]

    print("books")
    upsert("books", books, key)
    print("book_chapters")
    upsert("book_chapters", chapters, key, batch=50)

    research = []
    for item in companions:
        extras = [
            str(value)
            for key, value in item.items()
            if key not in {"id", "name", "arabic", "description"} and isinstance(value, str) and value.strip()
        ]
        body = "\n\n".join(part for part in [item.get("arabic") or "", item.get("description") or item.get("name") or "", *extras] if part)
        research.append(
            {
                "id": f"companion-{as_int(item['id'])}",
                "title": loc(item.get("name") or ""),
                "description": loc(item.get("arabic") or item.get("name") or ""),
                "body": loc(body),
                "author": loc("ئیمانی کورد"),
                "category": loc("هاوەڵان"),
                "reading_minutes": 4,
                "related_ids": [],
            }
        )
    print("research")
    upsert("research", research[:5], key)

    videos = [
        {
            "id": "vid-ayah",
            "title": loc("ڕوونکردنەوەی ئایەتی زانست", "ڕوونکرنا ئایەتێ زانستێ"),
            "description": loc("خوێندنەوەیەکی ئارام بۆ ئایەتی «رَبِّ زِدْنِي عِلْمًا».", "خاندنەکا ئارام بۆ ئایەتێ «رَبِّ زِدْنِي عِلْمًا»."),
            "category": loc("ڕوونکردنەوەی ئایەت", "ڕوونکرنا ئایەتێ"),
            "duration_label": "08:20",
            "thumbnail_url": "",
            "featured": True,
            "related_ids": [],
        },
    ]
    print("videos")
    upsert("videos", videos[:1], key)

    questions = [
        {
            "id": f"hadith-{as_int(item['id'])}",
            "question": loc(item.get("title") or ""),
            "answer": loc("\n\n".join(part for part in [item.get("arabic") or "", item.get("kurdish") or ""] if part.strip())),
            "category": loc("فەرموودە"),
            "related_verse_ids": [],
            "related_topic_ids": [],
        }
        for item in hadiths
    ]
    print("questions")
    upsert("questions", questions[:5], key)

    keep_topics = {"dhikr-1", "dhikr-27", "dhikr-28", "dhikr-29", "seerah"}
    topics = []
    articles = []
    for category in dhikr.get("categories") or []:
        topic_id = f"dhikr-{as_int(category['id'])}"
        if topic_id not in keep_topics:
            continue
        topics.append(
            {
                "id": topic_id,
                "title": loc(category.get("name") or ""),
                "introduction": loc(category.get("name") or ""),
                "verse_ids": [],
                "video_ids": [],
                "related_topic_ids": [],
            }
        )
        order = 0
        for item in dhikr.get("items") or []:
            if as_int(item.get("categoryId") or 0) != as_int(category["id"]):
                continue
            order += 1
            articles.append(
                {
                    "id": f"dhikr-item-{as_int(item['id'])}",
                    "topic_id": topic_id,
                    "title": loc(item.get("kurdish") or ""),
                    "body": loc(f"{item.get('arabic') or ''}\n\n{item.get('kurdish') or ''}"),
                    "sort_order": order,
                }
            )
    topics.append(
        {
            "id": "seerah",
            "title": loc("ژیاننامەی پێغەمبەر"),
            "introduction": loc("ڕووداوەکانی سیرە لە ئیمانی کورد"),
            "verse_ids": [],
            "video_ids": [],
            "related_topic_ids": [],
        }
    )
    order = 0
    for period in seerah:
        for event in period.get("events") or []:
            order += 1
            articles.append(
                {
                    "id": f"seerah-{as_int(event['id'])}",
                    "topic_id": "seerah",
                    "title": loc(event.get("title") or ""),
                    "body": loc(
                        "\n".join(
                            part
                            for part in [
                                event.get("titleArabic") or "",
                                event.get("hijriDate") or event.get("date") or "",
                                event.get("description") or "",
                            ]
                            if part
                        )
                    ),
                    "sort_order": order,
                }
            )
    print("topics")
    upsert("topics", topics, key)
    print("topic_articles")
    upsert("topic_articles", articles, key, batch=40)

    ayahs = quran["ayahs"]
    day = date.today().timetuple().tm_yday - 1
    daily_ayah = ayahs[day % len(ayahs)]
    daily_surah = as_int(daily_ayah["surah"])
    daily_ayah_no = as_int(daily_ayah["ayah"])
    daily_meaning = loc(
        sorani.get((daily_surah, daily_ayah_no), ""),
        badini.get((daily_surah, daily_ayah_no), "") or None,
    )
    daily_name = names[day % len(names)]
    daily_hadith = hadiths[day % len(hadiths)]
    print("daily_content")
    upsert(
        "daily_content",
        [
            {
                "id": date.today().isoformat(),
                "verse_id": f"{daily_surah}-{daily_ayah_no}",
                "arabic": daily_ayah.get("text") or "",
                "translation": daily_meaning,
                "topic_id": "dhikr-1",
                "topic_title": loc(daily_hadith.get("title") or ""),
                "word_id": f"name-{as_int(daily_name['id'])}",
                "message": loc(daily_hadith.get("kurdish") or ""),
            }
        ],
        key,
        batch=1,
    )

    print("app_config")
    upsert(
        "app_config",
        [
            {
                "id": "default",
                "whatsapp_number": "",
                "whatsapp_prefill": loc("سڵاو، پرسیارێکم هەیە سەبارەت بە رووناهى.", "سلاڤ، پسیارەکە هەیە لدور رووناهى."),
                "content_version": "2",
                "privacy_url": "https://rounahi.app/privacy",
                "terms_url": "https://rounahi.app/terms",
                "support_email": "",
                "about_body": loc(
                    "رووناهى پلاتفۆڕمێکی کوردییە بۆ خوێندنەوە، توێژینەوە و تێگەیشتنی قورئان. مەبەست لە ناوەکە ڕووناهییە: ڕوونکردنەوەی واتای ئایەت و وشە و بابەت بە زمانێکی ئارام و متمانەپێکراو.",
                    "رووناهى پلاتفۆرمایەکا کوردییە بۆ خاندن، ڤەکولین و تێگەهشتنا قورئانێ. مەبەست ژ ناڤی ڕووناهییە: ڕوونکرنا رامانا ئایەت و پەیڤ و بابەتان ب زمانەکێ ئارام.",
                ),
                "mission_body": loc(
                    "ئامانجی رووناهى ئەوەیە خوێنەری کورد بتوانێت قورئان بخوێنێتەوە، واتای ئایەت و وشەکان تێبگات، توێژینەوە و ڤیدیۆ ببینێت، و پرسیارەکانی بە شێوەیەکی ڕێکخراو بدۆزێتەوە.",
                    "ئارمانجا رووناهى ئەوەیە خواندەڤانێ کورد بشێت قورئانێ بخوێنیت، رامانا ئایەت و پەیڤان تێبگەهیت، ڤەکولین و ڤیدیویان ببینیت، و پسیارێن خۆ ب شێوەیەکێ ڕێکخستی بدۆزیت.",
                ),
                "team_body": loc(
                    "ناوەڕۆک لە پانێلی بەڕێوەبردنەوە نوێ دەکرێتەوە بێ ئەوەی وەشانێکی نوێی ئەپ پێویست بێت.",
                    "ناڤەڕۆک ژ پانێلا بەڕێڤەبرنێ دهێتە نووکرن.",
                ),
            }
        ],
        key,
        batch=1,
    )
    print("done")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(1)
