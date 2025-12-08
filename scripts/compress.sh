#!/bin/bash

# --- Configuration Variables ---
DEFAULT_CRF=23
AUDIO_BITRATE="128k"
TARGET_SIZE_MB="" # Default is empty, triggers CRF mode

# --- Function Definitions ---

# Function to print usage instructions
usage() {
    echo "Usage: $0 <input_file_path> [-t <target_size_MB>]"
    echo ""
    echo "Arguments:"
    echo "  <input_file_path> : The full path to the video file you want to compress."
    echo ""
    echo "Options:"
    echo "  -t <size_in_MB>   : Optional target size in megabytes (MB) for the video file."
    echo "                    If not specified, uses CRF mode (default CRF $DEFAULT_CRF)."
    echo ""
    echo "Example (CRF mode): ./compress_file.sh ./videos/my_trip.mp4"
    echo "Example (Target MB): ./compress_file.sh ./videos/my_trip.mp4 -t 50"
    exit 1
}

# Function to calculate video bitrate for a target size
calculate_bitrate() {
    local input_file="$1"
    local target_size="$2"

    # Get duration and audio bitrate using ffprobe
    local duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")
    # Use a default audio bitrate if ffprobe fails to find it or if the stream is complex
    local audio_bitrate_kbps=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$input_file" | awk '{print int($1/1024)}')
    audio_bitrate_kbps=${audio_bitrate_kbps:-128} # Default to 128k if empty

    # Calculate target video bitrate in kbits/s
    # Formula: (Target Size in Mbits - Audio Size in Mbits) / Duration in seconds
    # 8192 = 8 * 1024
    local target_bitrate_kbps=$(awk -v size="$target_size" -v duration="$duration" -v abrate="$audio_bitrate_kbps" \
    'BEGIN { printf "%.0f", ( (size * 8192) / duration - abrate ) }')

    if [[ "$target_bitrate_kbps" -le 0 ]]; then
        echo "Warning: Target size ${target_size}MB is too small for the audio stream in $input_file. Using default CRF instead." >&2
        echo "CRF"
    else
        echo "$target_bitrate_kbps"
    fi
}

# --- Argument Parsing ---

while getopts "t:" opt; do
    case "$opt" in
        t)
            TARGET_SIZE_MB="$OPTARG"
            if ! [[ "$TARGET_SIZE_MB" =~ ^[0-9]+$ ]]; then
                echo "Error: Target size must be a positive integer." >&2
                usage
            fi
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

shift $((OPTIND - 1))


# The first non-option argument should be the input file path
INPUT_FILE="$1"

# --- Validation ---
if [ -z "$INPUT_FILE" ]; then
    echo "Error: Missing input file path." >&2
    usage
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found at '$INPUT_FILE'." >&2
    exit 1
fi

# --- Main Logic ---

# Determine the output file path (same directory, append _compressed)
DIR_NAME=$(dirname "$INPUT_FILE")
BASE_NAME=$(basename -- "$INPUT_FILE")
EXTENSION="${BASE_NAME##*.}"
FILENAME_NOEXT="${BASE_NAME%.*}"
OUTPUT_FILE="$DIR_NAME/${FILENAME_NOEXT}_compressed.$EXTENSION"

echo "Input File: $INPUT_FILE"
echo "Output File: $OUTPUT_FILE"

FFMPEG_CMD="ffmpeg -y -i \"$INPUT_FILE\""

if [ -n "$TARGET_SIZE_MB" ]; then
    echo "Mode: Target Size (${TARGET_SIZE_MB}MB)"
    BITRATE_KBPS=$(calculate_bitrate "$INPUT_FILE" "$TARGET_SIZE_MB")

    if [ "$BITRATE_KBPS" = "CRF" ]; then
         FFMPEG_CMD+=" -c:v libx264 -crf $DEFAULT_CRF -c:a aac -b:a $AUDIO_BITRATE"
         echo "  > Falling back to CRF $DEFAULT_CRF"
    else
         echo "  > Processing with bitrate ${BITRATE_KBPS}k"
         # Pass 1
         ffmpeg -y -i "$INPUT_FILE" -c:v libx264 -b:v "${BITRATE_KBPS}k" -pass 1 -preset medium -tune film -threads 0 -f mp4 /dev/null
         # Pass 2 command is built below
         FFMPEG_CMD+=" -c:v libx264 -b:v \"${BITRATE_KBPS}k\" -pass 2 -preset medium -c:a aac -b:a \"$AUDIO_BITRATE\""
    fi
else
    echo "Mode: Constant Rate Factor (CRF $DEFAULT_CRF)"
    FFMPEG_CMD+=" -c:v libx264 -crf $DEFAULT_CRF -c:a aac -b:a $AUDIO_BITRATE"
fi

# Execute the final command
eval "$FFMPEG_CMD \"$OUTPUT_FILE\""

if [ $? -eq 0 ]; then
    echo "Compression complete. Output file created at: $OUTPUT_FILE"
else
    echo "Compression failed."
    exit 1
fi
