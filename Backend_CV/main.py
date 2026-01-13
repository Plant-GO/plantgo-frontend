import io
import os
import numpy as np
from PIL import Image
import base64

from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
import tensorflow as tf


# Get the directory where main.py is located
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "PlantgoVGG16_final.h5")

CLASS_NAMES = [
    "marigold",
    "Sabal Minor"
]

# Confidence thresholds (margin-based)
LOCAL_MODEL_MARGIN_THRESHOLD = 0.98  # 70% margin between top 2 predictions

# =====================================================
# PRE-CACHED PLANT METADATA (from Plant.id API)
# =====================================================
# This metadata was fetched once from Plant.id API and cached here
# to provide enriched responses without runtime API calls

PLANT_METADATA = {
    "marigold": {
        "scientific_name": "Tagetes erecta",
        "common_names": ["Aztec marigold", "Mexican marigold", "African Marigold"],
        "description": "Tagetes erecta, the Aztec marigold, Mexican marigold, big marigold, cempaxochitl or cempasúchil, is a species of flowering plant in the genus Tagetes native to Mexico and Guatemala. Despite being native to the Americas, it is often called the African marigold. This plant reaches heights of between 20 and 90 cm. The Aztecs gathered the wild plant as well as cultivating it for medicinal, ceremonial and decorative purposes.",
        "taxonomy": {
            "class": "Magnoliopsida",
            "genus": "Tagetes",
            "order": "Asterales",
            "family": "Asteraceae",
            "phylum": "Tracheophyta",
            "kingdom": "Plantae"
        },
        "image_url": "https://plant-id.ams3.cdn.digitaloceanspaces.com/knowledge_base/wikidata/263/26308f0530ab1fe4b37e9fe1ee5fb92363077916.jpg"
    },
    "Sabal Minor": {
        "scientific_name": "Sabal minor",
        "common_names": ["dwarf palmetto", "palmetto", "blue-stem palmetto", "bluestem palm"],
        "description": "Sabal minor, commonly known as the dwarf palmetto, is a small species of palm. It is native to the deep southeastern and south-central United States and northeastern Mexico. It is naturally found in a diversity of habitats, including maritime forests, swamps, floodplains, and occasionally on drier sites. It is often found growing in calcareous marl soil. Sabal minor is one of the most frost and cold tolerant among North American palms.",
        "taxonomy": {
            "class": "Liliopsida",
            "genus": "Sabal",
            "order": "Arecales",
            "family": "Arecaceae",
            "phylum": "Tracheophyta",
            "kingdom": "Plantae"
        },
        "image_url": "https://plant-id.ams3.cdn.digitaloceanspaces.com/knowledge_base/wikidata/7ee/7ee5477ed849a873ec8b628c0a54a62de8617903.jpg"
    }
}

# Load model at startup
model = tf.keras.models.load_model(MODEL_PATH)

app = FastAPI(title="Plant Prediction API")

# Add CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =====================================================
# IMAGE PREPROCESSING
# =====================================================

def preprocess_image(image_bytes: bytes):
    """Preprocess image for VGG16 model input."""
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image = image.resize((224, 224))
    image = np.array(image) / 255.0
    image = np.expand_dims(image, axis=0)
    return image

# =====================================================
# LOCAL MODEL PREDICTION (MARGIN-BASED)
# =====================================================

def predict_local_model(image_bytes: bytes):
    """
    Run inference on local VGG16 model using margin-based confidence.
    Returns plant name, margin (difference between top 2 predictions), and raw confidence.
    """
    image = preprocess_image(image_bytes)
    preds = model.predict(image, verbose=0)[0]

    # Sort probabilities to get margin
    sorted_preds = np.sort(preds)[::-1]
    margin = float(sorted_preds[0] - sorted_preds[1])

    # Get top prediction
    class_index = int(np.argmax(preds))
    plant_name = CLASS_NAMES[class_index]
    confidence = float(preds[class_index])

    # Check if margin meets threshold
    is_identified = margin >= LOCAL_MODEL_MARGIN_THRESHOLD

    # Simplified terminal log

    print(f"\n🌿{plant_name}")

    return plant_name, margin, confidence, is_identified

# =====================================================
# API ENDPOINTS
# =====================================================

@app.post("/predict-plant")
async def predict_plant(image: UploadFile = File(...)):
    """
    Identify plant using local VGG16 model with margin-based confidence.
    Returns 'identified' or 'unidentified' status based on margin threshold.
    """

    # Validate file type
    if image.content_type not in ["image/jpeg", "image/png", "image/jpg"]:
        raise HTTPException(
            status_code=400,
            detail="Only JPG and PNG images are allowed"
        )

    image_bytes = await image.read()

    # Run local model prediction
    plant_name, margin, confidence, is_identified = predict_local_model(image_bytes)

    if not is_identified:
        # Return unidentified status
        return {
            "status": "unidentified",
            "source": "local_model",
            "local_prediction": plant_name,
            "local_margin": round(margin, 3),
            "local_confidence": round(confidence, 3),
            "result": {
                "is_plant": {"binary": False, "probability": confidence},
                "classification": {"suggestions": []}
            }
        }

    # Get cached metadata for the identified plant
    metadata = PLANT_METADATA.get(plant_name, {})

    # Return unified response format (matches Plant.id structure)
    return {
        "status": "identified",
        "source": "local_model",
        "result": {
            "is_plant": {
                "binary": True,
                "probability": confidence
            },
            "classification": {
                "suggestions": [
                    {
                        "name": metadata.get("scientific_name", plant_name),
                        "probability": confidence,
                        "details": {
                            "common_names": metadata.get("common_names", [plant_name]),
                            "description": {
                                "value": metadata.get("description", "No description available.")
                            },
                            "taxonomy": metadata.get("taxonomy", {}),
                            "image": {
                                "value": metadata.get("image_url")
                            }
                        }
                    }
                ]
            }
        }
    }


@app.post("/predict-plant-base64")
async def predict_plant_base64(image_base64: str = Form(...)):
    """
    Identify plant from base64 encoded image.
    Alternative endpoint for Flutter app using base64 directly.
    """

    try:
        # Decode base64 image
        image_bytes = base64.b64decode(image_base64)
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid base64 image: {str(e)}"
        )

    # Run local model prediction
    plant_name, margin, confidence, is_identified = predict_local_model(image_bytes)

    if not is_identified:
        # Return unidentified status
        return {
            "status": "unidentified",
            "source": "local_model",
            "local_prediction": plant_name,
            "local_margin": round(margin, 3),
            "local_confidence": round(confidence, 3),
            "result": {
                "is_plant": {"binary": False, "probability": confidence},
                "classification": {"suggestions": []}
            }
        }

    # Get cached metadata for the identified plant
    metadata = PLANT_METADATA.get(plant_name, {})

    # Return unified response format (matches Plant.id structure)
    return {
        "status": "identified",
        "source": "local_model",
        "result": {
            "is_plant": {
                "binary": True,
                "probability": confidence
            },
            "classification": {
                "suggestions": [
                    {
                        "name": metadata.get("scientific_name", plant_name),
                        "probability": confidence,
                        "details": {
                            "common_names": metadata.get("common_names", [plant_name]),
                            "description": {
                                "value": metadata.get("description", "No description available.")
                            },
                            "taxonomy": metadata.get("taxonomy", {}),
                            "image": {
                                "value": metadata.get("image_url")
                            }
                        }
                    }
                ]
            }
        }
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "model_loaded": model is not None}