"""
One-time script to fetch real Plant.id metadata for the 2 plant types.
Run once, copy output to main.py PLANT_METADATA dict.
"""
import requests
import json
import base64
import os
from dotenv import load_dotenv

# Load API key from .env file
load_dotenv()
API_KEY = os.getenv("API_KEY")

if not API_KEY:
    print("ERROR: API_KEY not found in .env file")
    exit(1)

print(f"Using API key from .env: {API_KEY[:10]}...")

# Local images in Backend_CV folder
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
plants = {
    "marigold": os.path.join(BASE_DIR, "marigold.png"),
    "Sabal Minor": os.path.join(BASE_DIR, "sabalminor1.png")
}

metadata_results = {}

for plant_name, image_path in plants.items():
    print(f"\n{'='*50}")
    print(f"Fetching metadata for: {plant_name}")
    print(f"Image: {image_path}")
    print(f"{'='*50}")
    
    try:
        # Read local image and convert to base64
        with open(image_path, "rb") as f:
            img_base64 = base64.b64encode(f.read()).decode('utf-8')
        
        # Initial identification with base64
        response = requests.post(
            "https://api.plant.id/v3/identification",
            headers={"Api-Key": API_KEY, "Content-Type": "application/json"},
            json={"images": [f"data:image/png;base64,{img_base64}"], "similar_images": True}
        )
        
        if response.status_code != 200 and response.status_code != 201:
            print(f"Error: {response.status_code} - {response.text}")
            continue
            
        data = response.json()
        access_token = data.get("access_token")
        
        if not access_token:
            print("No access token received")
            continue
        
        # Fetch detailed info
        details_response = requests.get(
            f"https://api.plant.id/v3/identification/{access_token}?details=common_names,taxonomy,description,image",
            headers={"Api-Key": API_KEY}
        )
        
        if details_response.status_code != 200:
            print(f"Details error: {details_response.status_code}")
            continue
            
        details_data = details_response.json()
        
        # Extract relevant info from top suggestion
        result = details_data.get("result", {})
        classification = result.get("classification", {})
        suggestions = classification.get("suggestions", [])
        
        if not suggestions:
            print("No suggestions found")
            continue
            
        top = suggestions[0]
        top_details = top.get("details", {})
        
        metadata_results[plant_name] = {
            "scientific_name": top.get("name", plant_name),
            "common_names": top_details.get("common_names", [plant_name]),
            "description": top_details.get("description", {}).get("value", "No description available."),
            "taxonomy": top_details.get("taxonomy", {}),
            "image_url": top_details.get("image", {}).get("value", "")
        }
        
        print(f"Scientific name: {metadata_results[plant_name]['scientific_name']}")
        print(f"Common names: {metadata_results[plant_name]['common_names']}")
        print(f"Description: {metadata_results[plant_name]['description'][:100]}...")
        
    except Exception as e:
        print(f"Error processing {plant_name}: {e}")

# Output as Python dict for copy-paste
print("\n\n" + "="*60)
print("COPY THIS TO main.py PLANT_METADATA:")
print("="*60)
print("\nPLANT_METADATA = " + json.dumps(metadata_results, indent=4))
