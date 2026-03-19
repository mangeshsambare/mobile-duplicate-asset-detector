#!/bin/bash
set -e


ROOT_DIR="${1:-.}"
TEMP_FILE=$(mktemp)
duplicates_found=0


echo "🔍 Scanning drawables in: $ROOT_DIR"


# Check if we're on macOS and adjust commands accordingly
if [[ "$OSTYPE" == "darwin"* ]]; then
   MD5_CMD="md5 -r"
   XMLLINT_CMD="xmllint"
   # Check if xmllint is available
   if ! command -v xmllint &> /dev/null; then
       echo "⚠️  xmllint not found. Please install it with: brew install libxml2"
       exit 127
   fi
else
   MD5_CMD="md5sum"
   XMLLINT_CMD="xmllint"
fi


# Function to check if hash already exists
check_duplicate() {
   local hash="$1"
   local file="$2"


   if grep -q "^$hash " "$TEMP_FILE" 2>/dev/null; then
       local existing_file=$(grep "^$hash " "$TEMP_FILE" | cut -d' ' -f2-)
       echo "🔁 Duplicate found: $file == $existing_file"
       return 0
   else
       echo "$hash $file" >> "$TEMP_FILE"
       return 1
   fi
}


while read -r file; do
   if [[ "$file" == *drawable* ]]; then
       if [[ "$file" == *.xml ]]; then
           canonical=$(${XMLLINT_CMD} --noblanks "$file" 2>/dev/null || echo "")
           if [[ -z "$canonical" ]]; then
               echo "❌ Skipping invalid XML: $file"
               continue
           fi
           hash=$(echo "$canonical" | ${MD5_CMD} | awk '{print $1}')
       else
           hash=$(${MD5_CMD} "$file" | awk '{print $1}')
       fi


       if check_duplicate "$hash" "$file"; then
           duplicates_found=1
       fi
   fi
done < <(find "$ROOT_DIR" -type f \( -name "*.png" -o -name "*.webp" -o -name "*.xml" \))


# Clean up temp file
rm -f "$TEMP_FILE"


if [[ $duplicates_found -eq 1 ]]; then
   echo "❌ Duplicate drawables found. Please clean them up."
   exit 1
else
   echo "✅ No duplicate drawables found."
   exit 0
fi
