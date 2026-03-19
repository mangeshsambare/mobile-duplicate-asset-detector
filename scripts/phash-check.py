from PIL import Image
import imagehash
import os

threshold = 5
hashes = {}

print("🔍 Running pHash similarity check...")

for root, _, files in os.walk("."):
    for file in files:
        if file.lower().endswith((".png", ".jpg", ".jpeg")):
            path = os.path.join(root, file)
            try:
                img = Image.open(path)
                phash = imagehash.phash(img)

                for existing_path, existing_hash in hashes.items():
                    if phash - existing_hash <= threshold:
                        print(f"⚠️ Similar images: {path} ~ {existing_path}")

                hashes[path] = phash

            except Exception:
                pass
