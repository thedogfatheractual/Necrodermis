#!/usr/bin/env python3
"""
necro_weather.py — Necrodermis SDDM Weather Widget
Pulls METAR for configured ICAO, outputs ASCII art + one-liner to /tmp/necro_weather.txt
Night-aware: clear conditions between 2200-0500 show moon instead of sun.
"""

import re
import json
import os
import configparser
import requests
from datetime import datetime, timezone

# ── CONFIG ──
OUTPUT_FILE = "/tmp/necro_weather.txt"
NIGHT_START = 22
NIGHT_END = 5

def _load_icao() -> str:
    """
    Read ICAO from sitrep's config.ini.
    Falls back to CYWG if the file is missing or the key isn't set.
    Path mirrors sitrep's own config location: ~/.config/sitrep/config.ini
    """
    config_path = os.path.expanduser("~/.config/sitrep/config.ini")
    if os.path.exists(config_path):
        cfg = configparser.ConfigParser()
        cfg.read(config_path)
        icao = cfg.get("Weather", "icao_code", fallback="").strip().upper()
        if icao and icao != "DISABLED" and re.fullmatch(r"[A-Z]{3,4}", icao):
            return icao
    return "CYWG"

ICAO = _load_icao()

# ── ASCII ART ──
ASCII = {
    "CLR_DAY": [
        "    \\   |   /   ",
        "     .---.      ",
        "  --( sun )--   ",
        "     `---'      ",
        "    /   |   \\   ",
    ],
    "CLR_NIGHT": [
        "        .       ",
        "    .-'   '-.   ",
        "   /  MOON   \\  ",
        "   \\         /  ",
        "    '-.___.--'  ",
    ],
    "FEW": [
        "    \\   |   /   ",
        "     .---.      ",
        "  --(     )--   ",
        "   __`---'__    ",
        "  (  cloud  )   ",
    ],
    "SCT": [
        "   .---.         ",
        "  (     )        ",
        "   `---'__       ",
        "  (  cloud  )    ",
        "   `--------'    ",
    ],
    "BKN": [
        "   .--.   .--.  ",
        "  (    ) (    ) ",
        "   `--'   `--'  ",
        "  .-----------. ",
        " (   overcast  )",
    ],
    "OVC": [
        "  .------------.",
        " (              )",
        " (   OVERCAST   )",
        " (              )",
        "  `------------'",
    ],
    "RA": [
        "   .----------. ",
        "  (   RAIN     )",
        "   `----------' ",
        "  / / / / / /   ",
        " / / / / / /    ",
    ],
    "SN": [
        "   .----------. ",
        "  (   SNOW     )",
        "   `----------' ",
        "  * * * * * *   ",
        " * * * * * *    ",
    ],
    "TSRA": [
        "   .----------. ",
        "  ( THUNDER RA )",
        "   `----------' ",
        "  ⚡/ ⚡/ ⚡/    ",
        " / ⚡/ ⚡/ ⚡    ",
    ],
    "FG": [
        "  ~~~~~~~~~~~~  ",
        "  ~ ~ ~ ~ ~ ~   ",
        "    F O G       ",
        "  ~ ~ ~ ~ ~ ~   ",
        "  ~~~~~~~~~~~~  ",
    ],
    "UNKNOWN": [
        "                ",
        "   ?????????    ",
        "   UNKNOWN WX   ",
        "   ?????????    ",
        "                ",
    ],
}


def fetch_metar(icao):
    url = f"https://aviationweather.gov/api/data/metar?format=raw&ids={icao}"
    try:
        r = requests.get(url, timeout=8)
        r.raise_for_status()
        return r.text.strip()
    except Exception:
        return None


def parse_condition(metar):
    DESCRIPTORS = r'(?:VC|MI|BC|PR|DR|BL|SH|TS|FZ)'
    PRECIP = r'(?:DZ|RA|SN|SG|IC|PL|GR|GS|UP|BR|FG|FU|VA|DU|SA|HZ|PO|SQ|FC|SS|DS)'
    pattern = r'(?<!\S)([+-]?' + DESCRIPTORS + r'?' + PRECIP + r'+)(?!\S)'
    m = re.search(pattern, metar)
    if m:
        return m.group(1).strip()
    for code in ("SKC", "CLR", "FEW", "SCT", "BKN", "OVC"):
        if code in metar:
            return code
    return "UNKNOWN"


def parse_temp(metar):
    m = re.search(r'\b(M?)(\d{2})/(M?)(\d{2})\b', metar)
    if m:
        temp = int(m.group(2)) * (-1 if m.group(1) == 'M' else 1)
        return f"{temp}°C"
    return "?°C"


def parse_wind(metar):
    m = re.search(r'\b(\d{3})(\d{2,3})(G(\d{2,3}))?KT\b', metar)
    if m:
        spd = int(m.group(2))
        gust = f" G{m.group(4)}kt" if m.group(4) else ""
        return f"{m.group(1)}°@{spd}kt{gust}"
    if re.search(r'\b00000KT\b', metar):
        return "CALM"
    if re.search(r'\bVRB\d+KT\b', metar):
        return "VRB"
    return "?"


def parse_flight_cat(metar):
    ceiling_ft = None
    vis_sm = None

    if re.search(r'\bP6SM\b', metar):
        vis_sm = 7.0
    else:
        m = re.search(r'\b(\d+)SM\b', metar)
        if m:
            vis_sm = float(m.group(1))

    for m in re.finditer(r'\b(BKN|OVC)(\d{3})\b', metar):
        alt_ft = int(m.group(2)) * 100
        if ceiling_ft is None or alt_ft < ceiling_ft:
            ceiling_ft = alt_ft

    cat = "VFR"
    if ceiling_ft is not None:
        if ceiling_ft < 500: cat = "LIFR"
        elif ceiling_ft < 1000: cat = "IFR"
        elif ceiling_ft <= 3000: cat = "MVFR"
    if vis_sm is not None:
        if vis_sm < 1.0: cat = "LIFR"
        elif vis_sm < 3.0 and cat not in ("LIFR",): cat = "IFR"
        elif vis_sm <= 5.0 and cat not in ("LIFR","IFR"): cat = "MVFR"
    return cat


def is_night():
    h = datetime.now().hour
    return h >= NIGHT_START or h < NIGHT_END


def get_art_key(condition):
    c = condition.upper()
    if any(x in c for x in ("SKC","CLR","CAVOK")):
        return "CLR_NIGHT" if is_night() else "CLR_DAY"
    if "TSRA" in c or "TS" in c: return "TSRA"
    if "FG" in c or "BR" in c: return "FG"
    if "SN" in c or "SG" in c: return "SN"
    if "RA" in c or "DZ" in c: return "RA"
    if "OVC" in c: return "OVC"
    if "BKN" in c: return "BKN"
    if "SCT" in c: return "SCT"
    if "FEW" in c: return "FEW"
    return "UNKNOWN"


def get_emoji(art_key):
    return {
        "CLR_DAY":  "☀️",
        "CLR_NIGHT": "🌙",
        "FEW":      "🌤️",
        "SCT":      "⛅",
        "BKN":      "🌥️",
        "OVC":      "☁️",
        "RA":       "🌧️",
        "SN":       "❄️",
        "TSRA":     "⛈️",
        "FG":       "🌫️",
        "UNKNOWN":  "🌡️",
    }.get(art_key, "🌡️")


def main():
    if not ICAO:
        return  # Weather disabled — nothing to write

    metar = fetch_metar(ICAO)
    if not metar:
        output = "WEATHER UNAVAILABLE\n-- NO METAR DATA --"
        with open(OUTPUT_FILE, 'w') as f:
            f.write(output)
        return

    condition = parse_condition(metar)
    temp = parse_temp(metar)
    wind = parse_wind(metar)
    cat = parse_flight_cat(metar)
    art_key = get_art_key(condition)
    art = ASCII.get(art_key, ASCII["UNKNOWN"])
    emoji = get_emoji(art_key)

    lines = []
    lines.append(f"{emoji}  {ICAO}  •  {condition}  •  {temp}  •  {wind}  •  {cat}")
    lines.append("")
    for line in art:
        lines.append(line)

    with open(OUTPUT_FILE, 'w') as f:
        f.write('\n'.join(lines))


if __name__ == "__main__":
    main()
