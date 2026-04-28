#!/bin/bash

HOSTS_FILE="/etc/hosts"
YOUTUBE_DOMAINS=(
    "youtube.com"
    "www.youtube.com"
    "m.youtube.com"
    "youtu.be"
    "youtube-nocookie.com"
)

if [[ "$(uname)" == "Darwin" ]]; then
    SED_INPLACE=(-i '')
else
    SED_INPLACE=(-i)
fi

# Function to add YouTube domains to hosts file
add_youtube_block() {
    echo "Blocking YouTube..."
    for domain in "${YOUTUBE_DOMAINS[@]}"; do
        if ! grep -qE "^127\.0\.0\.1[[:space:]]+${domain}[[:space:]]*$" "$HOSTS_FILE"; then
            echo "127.0.0.1 $domain" | sudo tee -a "$HOSTS_FILE" > /dev/null
            echo "Added $domain to $HOSTS_FILE"
        else
            echo "$domain already blocked in $HOSTS_FILE"
        fi
    done
    echo "YouTube blocking complete."
}

# Function to remove YouTube domains from hosts file
remove_youtube_block() {
    echo "Unblocking YouTube..."
    for domain in "${YOUTUBE_DOMAINS[@]}"; do
        if grep -qE "^127\.0\.0\.1[[:space:]]+${domain}[[:space:]]*$" "$HOSTS_FILE"; then
            sudo sed "${SED_INPLACE[@]}" -E "/^127\.0\.0\.1[[:space:]]+${domain}[[:space:]]*\$/d" "$HOSTS_FILE"
            echo "Removed $domain from $HOSTS_FILE"
        else
            echo "$domain not found in $HOSTS_FILE"
        fi
    done
    echo "YouTube unblocking complete."
}

# Main script logic
case "$1" in
    "enable")
        add_youtube_block
        ;;
    "disable")
        remove_youtube_block
        ;;
    *)
        echo "Usage: $0 {enable|disable}"
        exit 1
        ;;
esac
