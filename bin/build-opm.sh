#!/bin/bash
# Build OTOBOLinkServiceFAQMerge.opm from .sopm and source files.
# Does NOT require an OTOBO installation — portable build.
#
# Usage: ./bin/build-opm.sh
# Output: dist/OTOBOLinkServiceFAQMerge-<version>.opm

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOPM_FILE="$PROJECT_DIR/OTOBOLinkServiceFAQMerge.sopm"

if [ ! -f "$SOPM_FILE" ]; then
    echo "ERROR: $SOPM_FILE not found." >&2
    exit 1
fi

# Extract version from .sopm
VERSION=$(grep -oP '<Version>\K[^<]+' "$SOPM_FILE")
if [ -z "$VERSION" ]; then
    echo "ERROR: Could not extract version from .sopm" >&2
    exit 1
fi

OUTPUT_DIR="$PROJECT_DIR/dist"
mkdir -p "$OUTPUT_DIR"
OPM_FILE="$OUTPUT_DIR/OTOBOLinkServiceFAQMerge-${VERSION}.opm"

echo "Building OTOBOLinkServiceFAQMerge v${VERSION}..."

# Start building the OPM XML
{
    # Read .sopm line by line, replacing <File .../> with <File ...>base64</File>
    while IFS= read -r line; do
        if echo "$line" | grep -q '<File .*Location="'; then
            # Extract attributes
            PERMISSION=$(echo "$line" | grep -oP 'Permission="\K[^"]+')
            LOCATION=$(echo "$line" | grep -oP 'Location="\K[^"]+')

            FILE_PATH="$PROJECT_DIR/$LOCATION"
            if [ ! -f "$FILE_PATH" ]; then
                echo "ERROR: File not found: $FILE_PATH" >&2
                exit 1
            fi

            # Base64 encode the file content
            B64_CONTENT=$(base64 -w 0 "$FILE_PATH")

            echo "        <File Permission=\"${PERMISSION}\" Location=\"${LOCATION}\" Encode=\"Base64\">${B64_CONTENT}</File>"
        else
            echo "$line"
        fi
    done < "$SOPM_FILE"
} > "$OPM_FILE"

echo "Built: $OPM_FILE ($(du -h "$OPM_FILE" | cut -f1))"
