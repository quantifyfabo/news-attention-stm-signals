import requests
import time
import pandas as pd
import os
from datetime import datetime
import calendar

# Time of Configuration (DEZEMBER 2025)
API_KEY = "Input Here"
OUTPUT_FILE = "nyt_foreign_politics_2025_data.csv"

# Decide Starting Year and Starting Date for Articles Published
START_YEAR = 2024
START_MONTH = 9
SEARCH_URL = "https://api.nytimes.com/svc/search/v2/articlesearch.json"

def fetch_nyt_data_final():
    # Create Function to structure the downloaded articles
    if not os.path.exists(OUTPUT_FILE):
        cols = ["date", "headline", "snippet", "lead_paragraph", "desk", "section", "source"]
        pd.DataFrame(columns=cols).to_csv(OUTPUT_FILE, index=False)

    # Filter for defined years (START_YEAR)
    years_to_scrape = [y for y in [2024, 2025] if y >= START_YEAR]

    for year in years_to_scrape:
        current_start_month = START_MONTH if year == START_YEAR else 1
        
        for month in range(current_start_month, 13):
            if year == 2025 and month > datetime.now().month:
                break
                
            last_day = calendar.monthrange(year, month)[1]
            begin_date = f"{year}{month:02d}01"
            end_date = f"{year}{month:02d}{last_day}"
            
            print(f"\n--- Monat: {month}/{year} (01. bis {last_day}.) ---")
            
            # Seit limit of pages above real artcicles published to ensure downloading ALL aricles published each months
            page = 0
            while page < 100:
                params = {
                    "api-key": API_KEY,
                    "fq": 'desk:("Foreign", "Washington") AND section.name:("World")',
                    "begin_date": begin_date,
                    "end_date": end_date,
                    "page": str(page),
                    "sort": "newest"
                }
                
                try:
                    response = requests.get(SEARCH_URL, params=params)
                    
                    if response.status_code == 200:
                        data = response.json()
                        docs = data.get('response', {}).get('docs', [])
                        
                        if not docs:
                            print(f"Seite {page}: Keine weiteren Artikel. Monat beendet.")
                            break
                        
                        extracted_data = []
                        for doc in docs:
                            extracted_data.append({
                                "date": doc.get("pub_date"),
                                "headline": doc.get("headline", {}).get("main"),
                                "snippet": doc.get("snippet"),
                                "lead_paragraph": doc.get("lead_paragraph"),
                                "desk": doc.get("news_desk"), 
                                "section": doc.get("section_name"), 
                                "source": "NYT"
                            })
                        
                        pd.DataFrame(extracted_data).to_csv(OUTPUT_FILE, mode='a', header=False, index=False)
                        print(f"Seite {page}: {len(docs)} Artikel gesichert.")
                        page += 1 # Only when no error continue to next page
                        
                    elif response.status_code == 429:
                        # Nicht abbrechen, sondern warten und wiederholen
                        print(f"\nRate Limit (429) reached. wait 60s before next try (Seite {page})...")
                        time.sleep(60)
                        continue # Try same request (gleiche Seite)
                    else:
                        print(f"Fehler {response.status_code}: {response.text}")
                        break
                        
                except Exception as e:
                    print(f"Fehler: {e}")
                    time.sleep(5)
                
                # Standard-Pause between Calls
                time.sleep(12) 

if __name__ == "__main__":
    fetch_nyt_data_final()
