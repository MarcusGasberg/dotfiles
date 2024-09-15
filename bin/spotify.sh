#!/bin/sh

text="text"
alt="alt"
song="$(playerctl -p spotify metadata title) - $(playerctl -p spotify metadata artist)"
class="class"
percentage="100"

echo "{\"text\": \"$song\", \"class\": \"$class\", \"percentage\": $percentage }"

