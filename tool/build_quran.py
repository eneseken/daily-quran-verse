"""Regenerates assets/quran.json from the AlQuran Cloud API.

The Quran text ships with the app rather than being fetched at runtime, so
this is the one place that talks to the API. Run it when a translation
should be swapped or a new language added:

    python tool/build_quran.py

It downloads one full-Quran dump per edition, folds every translation into
the ayah it belongs to, and writes a single surah-grouped file. Editions
arrive with the same 114-surah / 6,236-ayah skeleton, so they can be walked
in lockstep — the script checks that alignment rather than trusting it,
since a silent mismatch would attach translations to the wrong ayahs.
"""

import json
import sys
import urllib.request
from pathlib import Path

API = "https://api.alquran.cloud/v1/quran"

ASSET = Path(__file__).resolve().parent.parent / "assets" / "quran.json"

ARABIC_EDITION = "quran-uthmani"

# Language code -> AlQuran Cloud edition identifier. Keys must match
# supportedQuranLanguages in lib/core/quran_language.dart, minus 'ar' —
# Arabic renders the ayah text itself, not a translation entry.
TRANSLATIONS = {
    "en": "en.sahih",          # Saheeh International
    "tr": "tr.diyanet",        # Diyanet İşleri
    "de": "de.bubenheim",      # Bubenheim & Elyas
    "fr": "fr.hamidullah",     # Muhammad Hamidullah
    "es": "es.cortes",         # Julio Cortés
    "ur": "ur.jalandhry",      # Fateh Muhammad Jalandhry
    "id": "id.indonesian",     # Kemenag
}

EXPECTED_SURAHS = 114
EXPECTED_AYAHS = 6236


def fetch(edition):
    print(f"  fetching {edition}...", flush=True)
    with urllib.request.urlopen(f"{API}/{edition}", timeout=120) as response:
        payload = json.load(response)
    if payload.get("code") != 200:
        sys.exit(f"{edition}: API returned {payload.get('code')}")
    return payload["data"]["surahs"]


def main():
    print(f"Downloading {1 + len(TRANSLATIONS)} editions:")
    arabic = fetch(ARABIC_EDITION)
    translations = {lang: fetch(ed) for lang, ed in TRANSLATIONS.items()}

    if len(arabic) != EXPECTED_SURAHS:
        sys.exit(f"expected {EXPECTED_SURAHS} surahs, got {len(arabic)}")

    surahs = []
    total_ayahs = 0

    for index, surah in enumerate(arabic):
        ayahs = []
        for ayah_index, ayah in enumerate(surah["ayahs"]):
            texts = {}
            for lang, edition_surahs in translations.items():
                other = edition_surahs[index]["ayahs"][ayah_index]
                if other["numberInSurah"] != ayah["numberInSurah"]:
                    sys.exit(
                        f"{lang}: ayah misaligned at surah "
                        f"{surah['number']}:{ayah['numberInSurah']}"
                    )
                texts[lang] = other["text"]

            ayahs.append(
                {
                    # Terse keys: these repeat 6,236 times, and spelling
                    # them out costs about a megabyte of asset for nothing.
                    # Parsed by Surah.fromJson in lib/models/surah.dart.
                    "n": ayah["numberInSurah"],
                    "g": ayah["number"],
                    "ar": ayah["text"],
                    "t": texts,
                }
            )
            total_ayahs += 1

        surahs.append(
            {
                "number": surah["number"],
                "nameArabic": surah["name"],
                "nameEnglish": surah["englishName"],
                "nameTranslation": surah["englishNameTranslation"],
                "revelationType": surah["revelationType"],
                "ayahs": ayahs,
            }
        )

    if total_ayahs != EXPECTED_AYAHS:
        sys.exit(f"expected {EXPECTED_AYAHS} ayahs, got {total_ayahs}")

    ASSET.parent.mkdir(parents=True, exist_ok=True)
    with ASSET.open("w", encoding="utf-8") as f:
        json.dump(surahs, f, ensure_ascii=False, separators=(",", ":"))

    size_mb = ASSET.stat().st_size / 1024 / 1024
    print(f"\nWrote {ASSET} ({size_mb:.1f} MB)")
    print(
        f"{len(surahs)} surahs, {total_ayahs} ayahs, "
        f"{len(TRANSLATIONS)} translations"
    )
    print("Run `flutter test test/quran_asset_test.dart` to verify.")


if __name__ == "__main__":
    main()
