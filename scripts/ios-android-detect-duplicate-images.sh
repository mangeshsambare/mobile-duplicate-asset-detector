#!/bin/bash
set -e

ROOT_DIR="${1:-.}"
TEMP_FILE=$(mktemp)
duplicates_found=0
ios_scanned=false
android_scanned=false

echo "🔍 Scanning for duplicate images in: $ROOT_DIR"

# Check if we're on macOS and adjust commands accordingly
if [[ "$OSTYPE" == "darwin"* ]]; then
   MD5_CMD="md5 -r"
   XMLLINT_CMD="xmllint"
   # Check if xmllint is available for Android XML processing
   if ! command -v xmllint &> /dev/null; then
       echo "⚠️  xmllint not found. Android XML support limited. Install with: brew install libxml2"
       XMLLINT_CMD=""
   fi
else
   MD5_CMD="md5sum"
   XMLLINT_CMD="xmllint"
fi

# Function to check if hash already exists
check_duplicate() {
   local hash="$1"
   local file="$2"
   local platform="$3"

   if grep -q "^$hash " "$TEMP_FILE" 2>/dev/null; then
       local existing_file=$(grep "^$hash " "$TEMP_FILE" | cut -d' ' -f2-)
       echo "🔁 [$platform] Duplicate found: $file == $existing_file"
       return 0
   else
       echo "$hash $file" >> "$TEMP_FILE"
       return 1
   fi
}

# Function to get image hash
get_image_hash() {
   local file="$1"
   
   if [[ "$file" == *.xml ]] && [[ -n "$XMLLINT_CMD" ]]; then
       # Android vector drawable - canonicalize XML
       local canonical=$(${XMLLINT_CMD} --noblanks "$file" 2>/dev/null || echo "")
       if [[ -z "$canonical" ]]; then
           echo "❌ Skipping invalid XML: $file" >&2
           return 1
       fi
       echo "$canonical" | ${MD5_CMD} | awk '{print $1}'
   else
       # Regular image file
       ${MD5_CMD} "$file" | awk '{print $1}'
   fi
}

# Function to scan Android drawables
scan_android_drawables() {
   echo "📱 Scanning Android drawables..."
   local found_drawables=false
   
   while read -r file; do
       if [[ "$file" == *drawable* ]]; then
           found_drawables=true
           local hash=$(get_image_hash "$file")
           [[ -n "$hash" ]] && check_duplicate "$hash" "$file" "Android" && duplicates_found=1
       fi
   done < <(find "$ROOT_DIR" -type f \( -name "*.png" -o -name "*.webp" -o -name "*.xml" -o -name "*.jpg" -o -name "*.jpeg" \))
   
   if [[ "$found_drawables" == "true" ]]; then
       android_scanned=true
       echo "✓ Android drawable scan completed"
   fi
}

# Function to scan iOS assets
scan_ios_assets() {
   echo "🍎 Scanning iOS assets..."
   local found_assets=false
   
   # Find all .xcassets directories
   while read -r xcassets_dir; do
       [[ -z "$xcassets_dir" ]] && continue
       found_assets=true
       
       echo "  📂 Scanning: $xcassets_dir"
       
       # Find all .imageset directories within xcassets
       while read -r imageset_dir; do
           [[ -z "$imageset_dir" ]] && continue
           
           # Process all image files in the imageset (excluding Contents.json)
           while read -r image_file; do
               [[ -z "$image_file" ]] && continue
               [[ "$image_file" == *"Contents.json" ]] && continue
               
               local hash=$(get_image_hash "$image_file")
               [[ -n "$hash" ]] && check_duplicate "$hash" "$image_file" "iOS" && duplicates_found=1
               
           done < <(find "$imageset_dir" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.svg" -o -name "*.pdf" -o -name "*.gif" \) 2>/dev/null)
           
       done < <(find "$xcassets_dir" -type d -name "*.imageset" 2>/dev/null)
       
   done < <(find "$ROOT_DIR" -type d -name "*.xcassets" 2>/dev/null)
   
   # Also scan for loose image files in iOS projects (not in xcassets)
   while read -r file; do
       # Skip files that are inside xcassets (already processed above)
       [[ "$file" == *.xcassets* ]] && continue
       # Skip Android drawable directories
       [[ "$file" == *drawable* ]] && continue
       
       found_assets=true
       local hash=$(get_image_hash "$file")
       [[ -n "$hash" ]] && check_duplicate "$hash" "$file" "iOS" && duplicates_found=1
       
   done < <(find "$ROOT_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.svg" -o -name "*.pdf" -o -name "*.gif" \) 2>/dev/null)
   
   if [[ "$found_assets" == "true" ]]; then
       ios_scanned=true
       echo "✓ iOS assets scan completed"
   fi
}

# Auto-detect and scan platforms
echo "🔎 Auto-detecting platforms..."

# Check for iOS assets
if find "$ROOT_DIR" -type d -name "*.xcassets" -print -quit 2>/dev/null | grep -q .; then
   scan_ios_assets
fi

# Check for Android drawables  
if find "$ROOT_DIR" -path "*drawable*" -type f \( -name "*.png" -o -name "*.webp" -o -name "*.xml" \) -print -quit 2>/dev/null | grep -q .; then
   scan_android_drawables
fi

# Clean up temp file
rm -f "$TEMP_FILE"

# Final report
echo ""
echo "📊 Scan Summary:"
[[ "$ios_scanned" == "true" ]] && echo "  ✓ iOS assets scanned"
[[ "$android_scanned" == "true" ]] && echo "  ✓ Android drawables scanned"

if [[ "$ios_scanned" == "false" ]] && [[ "$android_scanned" == "false" ]]; then
   echo "  ⚠️  No iOS (.xcassets) or Android (drawable) assets found in: $ROOT_DIR"
   echo "  💡 Make sure you're running this script from the root of your project"
   exit 0
fi

if [[ $duplicates_found -eq 1 ]]; then
   echo ""
   echo "❌ Duplicate images found. Please clean them up."
   exit 1
else
   echo ""
   echo "✅ No duplicate images found."
   exit 0
fi
