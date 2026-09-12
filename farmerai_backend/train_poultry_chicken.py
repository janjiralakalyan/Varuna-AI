"""
🐔 Poultry & Chicken Disease Vision Training Script
Supports BOTH TensorFlow/Keras and PyTorch automatically.
Exports lightweight models for Render.com Backend & Mobile.
"""

import os
import sys
import json
import time

# ------------------------------------------------------------------------------
# CONFIGURATION & PATHS
# ------------------------------------------------------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# Support passing custom dataset directory via CLI: python train_poultry_chicken.py --data_dir /path/to/dataset
import argparse
parser = argparse.ArgumentParser(description="Train Poultry Disease Model")
parser.add_argument("--data_dir", type=str, default=None, help="Path to poultry disease image dataset")
parser.add_argument("--epochs", type=int, default=15, help="Number of training epochs")
args, _ = parser.parse_known_args()

DATA_DIR = args.data_dir
if not DATA_DIR or not os.path.exists(DATA_DIR):
    possible_paths = [
        os.path.join(BASE_DIR, "data", "poultry_chicken"),
        os.path.join(BASE_DIR, "data", "poultry"),
        os.path.join(BASE_DIR, "data", "chicken"),
        os.path.join(BASE_DIR, "data", "Poultry_Diseases"),
        os.path.join(BASE_DIR, "data", "Chicken_Diseases"),
        os.path.join(BASE_DIR, "data", "Poultry Disease Detection Dataset"),
        os.path.join(BASE_DIR, "data", "Chicken Disease Image Classification")
    ]
    DATA_DIR = None
    for p in possible_paths:
        if os.path.exists(p) and any(os.path.isdir(os.path.join(p, d)) for d in os.listdir(p)):
            DATA_DIR = p
            break

if not DATA_DIR:
    print("❌ Error: Poultry disease dataset directory not found!")
    print("Please place your class folders inside 'farmerai_backend/data/poultry_chicken/'")
    print("Or specify via CLI: python train_poultry_chicken.py --data_dir <path_to_dataset>")
    sys.exit(1)

MODEL_DIR = os.path.join(BASE_DIR, "model")
os.makedirs(MODEL_DIR, exist_ok=True)

MODEL_OUTPUT_H5 = os.path.join(MODEL_DIR, "poultry_disease_model.h5")
MODEL_OUTPUT_TFLITE = os.path.join(MODEL_DIR, "poultry_disease_model.tflite")
LABELS_OUTPUT = os.path.join(MODEL_DIR, "poultry_disease_labels.json")

IMAGE_SIZE = (224, 224)
BATCH_SIZE = 32
NUM_EPOCHS = 15

# ------------------------------------------------------------------------------
# 1. TRY TENSORFLOW (DEFAULT PRE-INSTALLED IN ANACONDA)
# ------------------------------------------------------------------------------
def train_with_tensorflow():
    import tensorflow as tf
    from tensorflow import keras
    from tensorflow.keras import layers, models

    print(f"⚡ TensorFlow Version: {tf.__version__}")
    gpus = tf.config.list_physical_devices('GPU')
    print(f"🚀 GPUs Available: {gpus if gpus else 'Using CPU'}")

    print(f"📂 Loading images from: {DATA_DIR}")
    train_ds = tf.keras.utils.image_dataset_from_directory(
        DATA_DIR,
        validation_split=0.2,
        subset="training",
        seed=123,
        image_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE
    )
    val_ds = tf.keras.utils.image_dataset_from_directory(
        DATA_DIR,
        validation_split=0.2,
        subset="validation",
        seed=123,
        image_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE
    )

    class_names = train_ds.class_names
    num_classes = len(class_names)
    print(f"✅ Found {num_classes} classes: {class_names}")

    # Save class names
    with open(LABELS_OUTPUT, "w") as f:
        json.dump({i: name for i, name in enumerate(class_names)}, f, indent=2)
    print(f"📄 Saved labels to: {LABELS_OUTPUT}")

    # Data augmentation pipeline
    data_augmentation = keras.Sequential([
        layers.RandomFlip("horizontal"),
        layers.RandomRotation(0.1),
        layers.RandomZoom(0.1),
    ])

    AUTOTUNE = tf.data.AUTOTUNE
    train_ds = train_ds.map(lambda x, y: (data_augmentation(x, training=True), y)).prefetch(buffer_size=AUTOTUNE)
    val_ds = val_ds.prefetch(buffer_size=AUTOTUNE)

    # Base pretrained model (MobileNetV3-Large or EfficientNetB0)
    print("📦 Building MobileNetV3-Large architecture...")
    base_model = tf.keras.applications.MobileNetV3Large(
        input_shape=(224, 224, 3),
        include_top=False,
        weights='imagenet'
    )
    base_model.trainable = False

    inputs = keras.Input(shape=(224, 224, 3))
    x = tf.keras.applications.mobilenet_v3.preprocess_input(inputs)
    x = base_model(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.2)(x)
    outputs = layers.Dense(num_classes, activation='softmax')(x)
    model = keras.Model(inputs, outputs)

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=0.001),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )

    print(f"\n🚀 Training for {NUM_EPOCHS} epochs...")
    history = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=NUM_EPOCHS
    )

    # Save H5 Model
    model.save(MODEL_OUTPUT_H5)
    print(f"✅ Saved H5 Model to: {MODEL_OUTPUT_H5}")

    # Export to TFLite (for Flutter & lightweight CPU inference)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    with open(MODEL_OUTPUT_TFLITE, 'wb') as f:
        f.write(tflite_model)
    print(f"📱 Exported TFLite Model to: {MODEL_OUTPUT_TFLITE} ({os.path.getsize(MODEL_OUTPUT_TFLITE)/(1024*1024):.2f} MB)")

# ------------------------------------------------------------------------------
# 2. TRY PYTORCH IF INSTALLED
# ------------------------------------------------------------------------------
def train_with_pytorch():
    import torch
    import torch.nn as nn
    import torch.optim as optim
    from torch.utils.data import DataLoader, random_split
    from torchvision import transforms, datasets, models
    import copy

    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
    print(f"⚡ PyTorch Training on: {device}")

    data_transforms = {
        'train': transforms.Compose([
            transforms.Resize(IMAGE_SIZE),
            transforms.RandomHorizontalFlip(),
            transforms.RandomRotation(15),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ]),
        'val': transforms.Compose([
            transforms.Resize(IMAGE_SIZE),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ]),
    }

    full_dataset = datasets.ImageFolder(DATA_DIR, transform=data_transforms['train'])
    class_names = full_dataset.classes
    num_classes = len(class_names)

    with open(LABELS_OUTPUT, "w") as f:
        json.dump({i: name for i, name in enumerate(class_names)}, f, indent=2)

    train_size = int(0.8 * len(full_dataset))
    val_size = len(full_dataset) - train_size
    train_dataset, val_dataset = random_split(full_dataset, [train_size, val_size])

    train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=BATCH_SIZE, shuffle=False)

    model = models.mobilenet_v3_large(weights=models.MobileNet_V3_Large_Weights.DEFAULT)
    in_features = model.classifier[3].in_features
    model.classifier[3] = nn.Sequential(nn.Dropout(0.3), nn.Linear(in_features, num_classes))
    model = model.to(device)

    criterion = nn.CrossEntropyLoss()
    optimizer = optim.AdamW(model.parameters(), lr=0.0003)

    for epoch in range(NUM_EPOCHS):
        model.train()
        for inputs, labels in train_loader:
            inputs, labels = inputs.to(device), labels.to(device)
            optimizer.zero_grad()
            loss = criterion(model(inputs), labels)
            loss.backward()
            optimizer.step()
        print(f"Epoch [{epoch+1}/{NUM_EPOCHS}] complete")

    onnx_out = os.path.join(MODEL_DIR, "poultry_disease_model.onnx")
    model.eval().to("cpu")
    torch.onnx.export(model, torch.randn(1, 3, 224, 224), onnx_out, opset_version=14)
    print(f"✅ Exported ONNX Model to: {onnx_out}")

def main():
    try:
        import tensorflow as tf
        print("📦 Using TensorFlow framework for training...")
        train_with_tensorflow()
    except ImportError:
        try:
            import torch
            print("📦 Using PyTorch framework for training...")
            train_with_pytorch()
        except ImportError:
            print("❌ Neither TensorFlow nor PyTorch was found. Please run: pip install tensorflow OR pip install torch torchvision")

if __name__ == "__main__":
    main()
