import json
import requests
import os

# --- Configuration ---
MODEL_NAME = "qwen3:30b"
INPUT_FILE = "./scraper_output/scraped_content.jsonl"
OUTPUT_FILE = "./scraper_output/relevant_articles.jsonl"
PROGRESS_FILE = "./scraper_output/filter_progress.txt"
OLLAMA_API_URL = "http://localhost:11434/api/chat"
BATCH_SIZE = 10  # Save after every 5 articles

def get_last_processed():
    """Get the index of last processed article"""
    if os.path.exists(PROGRESS_FILE):
        with open(PROGRESS_FILE, 'r') as f:
            return int(f.read().strip())
    return 0

def save_progress(index):
    """Save current progress"""
    with open(PROGRESS_FILE, 'w') as f:
        f.write(str(index))

def save_article(article):
    """Append article to output file"""
    with open(OUTPUT_FILE, 'a', encoding='utf-8') as f:
        f.write(json.dumps(article, ensure_ascii=False) + '\n')

def check_relevance(title, content):
    """Check if article is about ICE (the federal agency)"""
    
    # Use first 1000 chars only
    text = f"{title}\n\n{content[:1000]}"
    
    prompt = f"""Is this article about ICE (Immigration and Customs Enforcement)?

Article:
{text}

Answer ONLY with one word: YES or NO

YES = about the federal agency ICE (immigration, deportation, raids, agents)
NO = about ice hockey, weather, cars, or anything else

Answer:"""

    payload = {
        "model": MODEL_NAME,
        "stream": False,
        "messages": [{"role": "user", "content": prompt}]
    }

    try:
        response = requests.post(OLLAMA_API_URL, json=payload, timeout=30)
        answer = response.json()['message']['content'].strip().upper()
        
        # Check if answer contains YES or NO
        if "YES" in answer:
            return "RELEVANT"
        elif "NO" in answer:
            return "IRRELEVANT"
        else:
            return f"UNCLEAR: {answer}"
        
    except Exception as e:
        return f"ERROR: {str(e)}"

def main():
    print("=== ICE Article Filter (with Resume) ===\n")
    
    # Load progress
    start_index = get_last_processed()
    if start_index > 0:
        print(f"📂 Resuming from article #{start_index}\n")
    else:
        print("🆕 Starting fresh\n")
        # Create/clear output file
        open(OUTPUT_FILE, 'w').close()
    
    relevant = 0
    irrelevant = 0
    errors = 0
    current_index = 0
    articles_in_batch = 0
    
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            for line in f:
                if not line.strip():
                    continue
                
                current_index += 1
                
                # Skip already processed articles
                if current_index <= start_index:
                    continue
                
                try:
                    article = json.loads(line)
                    title = article.get("title", "")
                    content = article.get("content", "")
                    
                    if not content:
                        continue

                    if 'hockey' in content.lower():
                        continue

                    if 'weather' in content.lower():
                        continue
                    
                    print(f"[{current_index}] {title[:60]}...")
                    
                    result = check_relevance(title, content)
                    
                    if result == "RELEVANT":
                        print("    ✅ RELEVANT")
                        relevant += 1
                        save_article(article)
                        
                    elif result == "IRRELEVANT":
                        print("    ❌ IRRELEVANT")
                        irrelevant += 1
                        
                    else:
                        print(f"    ⚠️  {result}")
                        errors += 1
                    
                    articles_in_batch += 1
                    
                    # Save progress every BATCH_SIZE articles
                    if articles_in_batch >= BATCH_SIZE:
                        save_progress(current_index)
                        print(f"    💾 Progress saved at article #{current_index}\n")
                        articles_in_batch = 0
                    else:
                        print()
                        
                except:
                    continue
        
        # Final save
        save_progress(current_index)
        print(f"✅ Final progress saved at article #{current_index}\n")
        
    except KeyboardInterrupt:
        print(f"\n\n⚠️  Interrupted! Progress saved at article #{current_index}")
        save_progress(current_index)
    
    print("\n=== SUMMARY ===")
    print(f"Processed:  {current_index - start_index}")
    print(f"Relevant:   {relevant}")
    print(f"Irrelevant: {irrelevant}")
    print(f"Errors:     {errors}")
    print(f"\n📁 Relevant articles saved to: {OUTPUT_FILE}")
    print(f"📊 Progress file: {PROGRESS_FILE}")
    print(f"\nTo resume later, just run this script again!")

if __name__ == "__main__":
    main()