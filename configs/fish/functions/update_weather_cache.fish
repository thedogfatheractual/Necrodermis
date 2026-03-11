#!/usr/bin/fish

# Define cache file path
set CACHE_FILE "$HOME/.cache/gemini_weather_cache.json"
set TIMESTAMP (date +%s) # Unix timestamp

# Fetch METAR and TAF
set METAR_DATA (curl -s "https://aviationweather.gov/api/data/metar?ids=CYWG&format=raw&hours=0")
set TAF_DATA (curl -s "https://aviationweather.gov/api/data/taf?ids=CYWG&format=raw&hours=0")

# Create JSON content
set JSON_CONTENT "{ "timestamp": "$TIMESTAMP", "metar": "$METAR_DATA", "taf": "$TAF_DATA" }"

# Write to cache file
echo $JSON_CONTENT > $CACHE_FILE
