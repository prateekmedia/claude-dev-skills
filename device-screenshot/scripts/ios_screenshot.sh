#!/bin/bash

# Final iPhone Screenshot Script
# Usage: ./ios_screenshot.sh [output_path]

OUTPUT_PATH="${1:-screenshot.png}"

echo "📱 Taking iPhone screenshot..."

# Record timestamp before taking screenshot
BEFORE_TIMESTAMP=$(date +%s)
DESKTOP_PATH="$HOME/Desktop"

# Check if device is connected
DEVICE_COUNT=$(xcrun devicectl list devices 2>/dev/null | grep -c "connected")
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "❌ No connected iOS devices found"
    echo "Please connect your iPhone via USB and ensure it's trusted"
    exit 1
fi

# Click button 3 (Take Screenshot)
APPLESCRIPT_RESULT=$(osascript -e '
tell application "Xcode"
    activate
    delay 0.5
end tell

tell application "System Events"
    tell process "Xcode"
        keystroke "2" using {shift down, command down}
        delay 1.5

        try
            set allElements to entire contents of window 1
            set buttonCount to 0
            repeat with element in allElements
                try
                    if class of element is button then
                        set buttonCount to buttonCount + 1
                        if buttonCount = 3 then
                            click element
                            return "clicked_button_3"
                        end if
                    end if
                end try
            end repeat
            return "button_3_not_reached"
        on error e
            return "error: " & e
        end try
    end tell
end tell')

if [[ "$APPLESCRIPT_RESULT" == "clicked_button_3" ]]; then
    # Wait for screenshot to be saved
    sleep 1

    # Look for screenshots created after our timestamp (within 30 seconds)
    AFTER_TIMESTAMP=$((BEFORE_TIMESTAMP + 30))
    VALID_SCREENSHOTS=()

    for screenshot in "$DESKTOP_PATH"/Screen*Shot*.png "$DESKTOP_PATH"/Screen*shot*.png "$DESKTOP_PATH"/Screenshot*.png; do
        if [ -f "$screenshot" ]; then
            FILE_TIMESTAMP=$(stat -f %B "$screenshot" 2>/dev/null)
            if [ -z "$FILE_TIMESTAMP" ] || [ "$FILE_TIMESTAMP" -eq 0 ]; then
                FILE_TIMESTAMP=$(stat -f %m "$screenshot" 2>/dev/null)
            fi

            if [ "$FILE_TIMESTAMP" -ge "$BEFORE_TIMESTAMP" ] && [ "$FILE_TIMESTAMP" -le "$AFTER_TIMESTAMP" ]; then
                VALID_SCREENSHOTS+=("$screenshot:$FILE_TIMESTAMP")
            fi
        fi
    done

    if [ ${#VALID_SCREENSHOTS[@]} -eq 0 ]; then
        echo "❌ No new screenshot found"
        exit 1
    fi

    # Get the most recent screenshot
    NEWEST_SCREENSHOT=""
    NEWEST_TIMESTAMP=0

    for screenshot_info in "${VALID_SCREENSHOTS[@]}"; do
        screenshot_path="${screenshot_info%:*}"
        timestamp="${screenshot_info#*:}"

        if [ "$timestamp" -gt "$NEWEST_TIMESTAMP" ]; then
            NEWEST_TIMESTAMP="$timestamp"
            NEWEST_SCREENSHOT="$screenshot_path"
        fi
    done

    # Copy to desired location
    cp "$NEWEST_SCREENSHOT" "$OUTPUT_PATH"

    if [ $? -eq 0 ]; then
        echo "✅ Screenshot saved to: $OUTPUT_PATH"

        # Auto-delete original if it's recent (within 10 seconds)
        CURRENT_TIME=$(date +%s)
        TIME_DIFF=$((CURRENT_TIME - NEWEST_TIMESTAMP))

        if [ "$TIME_DIFF" -le 10 ]; then
            rm "$NEWEST_SCREENSHOT"
        fi
    else
        echo "❌ Failed to copy screenshot"
        exit 1
    fi

else
    echo "❌ Failed to take screenshot: $APPLESCRIPT_RESULT"
    exit 1
fi
