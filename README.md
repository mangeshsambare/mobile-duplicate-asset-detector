# mobile-duplicate-asset-detector
# Duplicate Asset Detector (Android & iOS)

A lightweight tool to detect duplicate drawable and image assets across Android and iOS projects using content-based hashing.

---

## 🚨 Problem

Duplicate assets silently creep into codebases:
- Same image, different names
- Increased APK / IPA size
- Harder code reviews
- Wasted developer time in cleanup

---

## ✅ Solution

This tool detects duplicates using:
- MD5 content hashing (exact match)
- XML normalization (vector drawables)
- Optional pHash (visual similarity)

---

## 🔧 Features

- Supports PNG, WebP, XML, JPG
- Works on Android & iOS assets
- CI/CD friendly
- Fast (<30 seconds)
- Zero configuration

---

## 🚀 Usage

```bash
bash scripts/detect-duplicate-images.sh ./app/src/main/res/
