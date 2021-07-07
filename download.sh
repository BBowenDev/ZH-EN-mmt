#!/bin/bash

FV=$(pwd)

cd $FV/vatex/raw
mkdir videos
cd videos

function dw_all {
	local SEEN=0
	local ERR=0
	
	set -e
	input="${RAW}/*.ids"
	while IFS='_' read -r -a ARR; do 
	  ID=${ARR[0]}
	  IN=${ARR[1]}
	  OUT=${ARR[2]}
	  LN=$((${OUT}-${IN}))
	  
	  CHECK=$ERR
	  #for every video, download from timeframe
	  ffmpeg -ss $IN -i $(youtube-dl $ID -q -f mp4/bestvideo --external-downloader ffmpeg) -t $LN -vcodec copy || true; let ERR++
	  if [[ CHECK -eq ERR ]]; then
	  	let SEEN++
	  fi
	done
	
	echo "--Videos Downloaded: ${SEEN}"
	echo "--Videos Skipped: ${ERR}"
}

function dw_select {
	local NUM=$1
	local ERR=0
	local SEEN=0
	
	set -e
	input="${RAW}/*.ids"
	while IFS='_' read -r -a ARR; do 
	  if [[ SEEN -gte NUM ]]; then
	  	break
	  fi
	  
	  ID=${ARR[0]}
	  IN=${ARR[1]}
	  OUT=${ARR[2]}
	  LN=$((${OUT}-${IN})) 
	  
	  CHECK=$ERR
	  #for every video, download from timeframe
	  ffmpeg -ss $IN -i $(youtube-dl $ID -q -f mp4/bestvideo --external-downloader ffmpeg) -t $LN -vcodec copy || true; let ERR++
	  
	  if [[ CHECK -eq ERR ]]; then
	  	let SEEN++
	  fi
	done
	
	echo "--Videos Downloaded: ${SEEN}"
	echo "--Videos Skipped: ${ERR}"
}

if [ ! -z $1 ]; then
	dw_select $1
else
	dw_all
fi
