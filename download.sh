#!/bin/bash

function dw_all {
	echo "Downloading all VaTeX Videos"
	
	local SEEN=0
	local ERR=0

	set -e
	input="${RAW}/*.ids"
	while read l; do 
	  
	  
	  IFS='_' read -r -a ARR
	  
	  ID=${ARR[0]}
	  IN=${ARR[1]}
	  OUT=${ARR[2]}
	  LN=$((${OUT}-${IN}))
	  
	  CHECK=$ERR
	  #for every video, download from timeframe
	  echo "Starting Download ${SEEN}"
	  ffmpeg -ss $IN -i $(youtube-dl $ID -q -f mp4/bestvideo --external-downloader ffmpeg) -t $LN -vcodec copy || true; let ERR++
	  if [[ $CHECK -eq $ERR ]]; then
	  	let SEEN++
		echo "Successfully Downloaded ${SEEN} Videos"
	  fi
	done
	
	echo "--Videos Downloaded: ${SEEN}"
	echo "--Videos Skipped: ${ERR}"
}

function dw_select {
	echo "Downloading ${1} VaTeX Videos"
	
	local NUM=$1
	local ERR=0
	local SEEN=0
	
	set -e
	input="${RAW}/*.ids"
	while IFS='_' read -r -a ARR; do 
	  if [[ $SEEN -ge $NUM ]]; then
	  	break
	  fi
	  
	  ID=${ARR[0]}
	  IN=${ARR[1]}
	  OUT=${ARR[2]}
	  LN=$((${OUT}-${IN})) 
	  
	  CHECK=$ERR
	  #for every video, download from timeframe
	  echo "Starting Download ${SEEN}"
	  ffmpeg -ss $IN -i $(youtube-dl $ID -q -f mp4/bestvideo --external-downloader ffmpeg) -t $LN -vcodec copy || true; let ERR++
	  
	  if [[ $CHECK -eq $ERR ]]; then
	  	let SEEN++
		echo "Successfully Downloaded ${SEEN} Videos"
	  fi
	done
	
	echo "--Videos Downloaded: ${SEEN}"
	echo "--Videos Skipped: ${ERR}"
}

function test {
	
	for entry in "$RAW/"*.ids; do
		echo "Testing ${entry} with ${1} Lines"
		MAX=$1
		SEEN=0
		while read l; do
			if [[ $SEEN -ge $MAX ]]; then
				echo "Seen a maximum of ${SEEN} lines"	
			fi
			echo "$p"
		done <entry
	done
	
	
}


if [ -z $1 ]; then
	#dw_all
	test $1
else
	#dw_select $1
	test $1
fi
