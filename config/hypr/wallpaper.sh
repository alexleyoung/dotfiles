#!/bin/bash

# STRAIGHT FROM CHAT GPT
# Wait until all monitors are registered (adjust timeout as needed)
timeout=5
count=0

# Wait until we have more than 1 output (or however many you expect)
while [ $(hyprctl monitors | grep 'Monitor' | wc -l) -lt 2 ] && [ $count -lt $timeout ]; do
    sleep 0.5
    count=$((count + 1))
done

# Set wallpaper for each monitor
swww img /home/alex/Documents/wallpapers/wallpaper.png --transition-type any

