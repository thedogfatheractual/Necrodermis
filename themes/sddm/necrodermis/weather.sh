#!/bin/bash
# NECRODERMIS
# Weather fetcher for SDDM — Aviation Weather Center METAR
# Change ICAO to your nearest airport

ICAO="CYWG"

RESPONSE=$(curl -s --max-time 5 "https://aviationweather.gov/api/data/metar?ids=${ICAO}&format=json")

TEMP=$(echo "$RESPONSE" | jq -r '.[0].temp')
WX=$(echo "$RESPONSE" | jq -r '.[0].wxString // "clear"')
COVER=$(echo "$RESPONSE" | jq -r '.[0].cover // ""')

echo "${TEMP}°C  ${WX}" > /tmp/sddm-weather
echo "${WX}" > /tmp/sddm-weather-code

# ── MOON PHASE CALCULATION ──
# Reference new moon: 2000-01-06 (known new moon date)
REF_NEW_MOON=946944000  # Unix timestamp 2000-01-06 18:14 UTC
LUNAR_CYCLE=2551443     # 29.53059 days in seconds
NOW=$(date +%s)
ELAPSED=$(( NOW - REF_NEW_MOON ))
# bash can't do float mod so use python for precision
PHASE=$(python3 -c "
cycle = 2551443
elapsed = $ELAPSED
pos = elapsed % cycle
frac = pos / cycle
# 0=new, 0.25=first quarter, 0.5=full, 0.75=last quarter
if frac < 0.0625:
    print('NEW')
elif frac < 0.1875:
    print('WAXING_CRESCENT')
elif frac < 0.3125:
    print('FIRST_QUARTER')
elif frac < 0.4375:
    print('WAXING_GIBBOUS')
elif frac < 0.5625:
    print('FULL')
elif frac < 0.6875:
    print('WANING_GIBBOUS')
elif frac < 0.8125:
    print('LAST_QUARTER')
elif frac < 0.9375:
    print('WANING_CRESCENT')
else:
    print('NEW')
")

echo "${PHASE}" > /tmp/sddm-weather-moon
