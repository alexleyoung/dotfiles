#!/usr/bin/env bash

# initializing wallpaper daemon
swww init &

# setting wallpaper
swww img /home/alexy/Documents/wallpapers/singapore-wp.png &

# network manager applet
nm-applet --indicator &

# bar
waybar &

# dunst
dunst
