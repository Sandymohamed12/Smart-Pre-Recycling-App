import os
import numpy as np
from PIL import Image
import tensorflow as tf
from ultralytics import YOLO

# ================= PATHS =================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))

MODEL1_PATH = os.path.join(BASE_DIR, "models", "model1_full.keras")
MODEL2_PATH = os.path.join(BASE_DIR, "models", "model2.h5")
MODEL3_PATH = os.path.join(BASE_DIR, "models", "model3.pt")

# ================= LOAD MODELS =================
model1 = tf.keras.models.load_model(MODEL1_PATH)
model2 = tf.keras.models.load_model(MODEL2_PATH)
model3 = YOLO(MODEL3_PATH)

# ================= CLASS NAMES =================
class_names_model2 = [
    'E-waste',
    'automobile wastes',
    'battery waste',
    'glass waste',
    'light bulbs',
    'metal waste',
    'organic waste',
    'paper waste',
    'plastic waste'
]

# ================= PREPROCESS MODEL 1 =================
def preprocess_model1(img_path):
    img = tf.keras.preprocessing.image.load_img(img_path, target_size=(224, 224))
    img_array = tf.keras.preprocessing.image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    return img_array

# ================= PREPROCESS MODEL 2 =================
def preprocess_model2(img_path):
    img = tf.keras.preprocessing.image.load_img(img_path, target_size=(380, 380))
    img_array = tf.keras.preprocessing.image.img_to_array(img)
    img_array = tf.keras.applications.efficientnet.preprocess_input(img_array)
    img_array = np.expand_dims(img_array, axis=0)
    return img_array

# ================= MODEL 3 (YOLO) =================
def run_model3(img_path):
    results = model3(img_path)

    detections = []

    for r in results:
        boxes = r.boxes
        if boxes is None:
            continue

        for box in boxes:
            cls_id = int(box.cls[0])
            conf = float(box.conf[0])
            xyxy = box.xyxy[0].tolist()

            label = model3.names[cls_id]

            detections.append({
                "label": label,
                "confidence": round(conf, 3),
                "bbox": [round(x, 2) for x in xyxy]
            })

    return detections

# ================= PIPELINE =================
def run_pipeline(image_path):

    # ---------- MODEL 1 ----------
    img1 = preprocess_model1(image_path)
    pred1 = model1.predict(img1)

    prob = float(pred1[0][0])
    recyclable = prob < 0.5

    print("Model1 prob:", prob)
    print("Recyclable:", recyclable)

    # ---------- MODEL 2 ----------
    if recyclable:
        img2 = preprocess_model2(image_path)
        pred2 = model2.predict(img2)

        class_index = np.argmax(pred2)
        category = class_names_model2[class_index]

        print("Model2 category:", category)
    else:
        category = "Not recyclable"

    # ---------- MODEL 3 ----------
    detections = run_model3(image_path)

    print("YOLO detections:", detections)

    return {
        "recyclable": bool(recyclable),
        "category": category,
        "detections": detections
    }