#!/bin/bash

pip install youtube-dl
pip install ffmpeg

RAW=$FV/vatex/raw


input="${RAW}/*.ids"
while IFS='_' read -r -a ARR; do 
  ID=${ARR[0]}
  IN=${ARR[1]}
  OUT=${ARR[2]}
  LN=$((${OUT}-${IN}))
  
  #for every video
  ffmpeg -ss $IN -i $(youtube-dl $ID -q -f mp4/bestvideo --external-downloader ffmpeg) -t $LN -acodec copy -vcodec copy 
done
