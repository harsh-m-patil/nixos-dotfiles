#!/usr/bin/env bash
# Prints a random Doctor Who quote for the hyprlock screen,
# wrapped to ~44 chars per line (plain text, real newlines)
f="$HOME/.config/hypr/dw-quotes.txt"
shuf -n1 "$f" | fmt -w 44
