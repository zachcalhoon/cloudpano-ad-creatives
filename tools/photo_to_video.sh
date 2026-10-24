#!/usr/bin/env bash
# Build a ~14s 1080x1350 "photos -> AI walkthrough" style video.
# Usage: tools/photo_to_video.sh title.png overlay.png end.png photo1.jpg photo2.jpg photo3.jpg out.mp4
# title/end = full-frame PNG cards (render.py), overlay = transparent PNG (render.py --png-transparent)
set -e
T=$1; O=$2; E=$3; P1=$4; P2=$5; P3=$6; OUT=$7; W=$(mktemp -d)
i=0; for P in "$P1" "$P2" "$P3"; do i=$((i+1)); convert "$P" -resize 2160x2700^ -gravity center -extent 2160x2700 $W/k$i.jpg; done
kb(){ ffmpeg -y -loglevel error -loop 1 -i $1 -vf "zoompan=z='$2':x='$3':y='ih/2-(ih/zoom/2)':d=96:s=1080x1350:fps=30,format=yuv420p" -t 3.2 -c:v libx264 -preset veryfast -crf 20 $4; }
kb $W/k1.jpg "1+0.0025*on" "iw/2-(iw/zoom/2)" $W/c1.mp4
kb $W/k2.jpg "1.25" "(iw-iw/zoom)*on/96" $W/c2.mp4
kb $W/k3.jpg "1.3-0.003*on" "iw/2-(iw/zoom/2)" $W/c3.mp4
ffmpeg -y -loglevel error -loop 1 -i "$T" -vf "zoompan=z='1+0.0008*on':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=90:s=1080x1350:fps=30,format=yuv420p" -t 3 -c:v libx264 -preset veryfast -crf 20 $W/t.mp4
ffmpeg -y -loglevel error -loop 1 -i "$E" -vf format=yuv420p -r 30 -t 3.5 -c:v libx264 -preset veryfast -crf 20 $W/e.mp4
ffmpeg -y -loglevel error -i $W/c1.mp4 -i $W/c2.mp4 -i $W/c3.mp4 -i "$O" -filter_complex "[0][1]xfade=transition=fade:duration=0.5:offset=2.7[a];[a][2]xfade=transition=slideleft:duration=0.5:offset=5.4[b];[b][3]overlay=0:0,format=yuv420p[v]" -map "[v]" -c:v libx264 -preset veryfast -crf 20 $W/mid.mp4
ffmpeg -y -loglevel error -i $W/t.mp4 -i $W/mid.mp4 -i $W/e.mp4 -filter_complex "[0][1]xfade=transition=fade:duration=0.4:offset=2.6[a];[a][2]xfade=transition=fade:duration=0.4:offset=10.3,format=yuv420p[v]" -map "[v]" -c:v libx264 -preset veryfast -crf 23 -movflags +faststart "$OUT"
rm -rf $W; echo "$OUT"
