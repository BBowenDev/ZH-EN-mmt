#!/bin/bash

FV=$(pwd)
RAW=$FV/vatex/raw
VIDS=$RAW/vids

function download_all {
	for FILE in "$RAW"/*.ids; do 
		echo "remove later"	
	done
}

function download_select {
	echo "Downloading ${1} videos"
	MAX=$1
	SEEN=0
	ERR_ALL=0
	for FILE in "$RAW"/*.ids; do
		ERR=0
		while read -r L; do
			#if the given number of videos has been downloaded, break loop
			if [[ $SEEN -ge $MAX ]]; then 
				echo "Seen a Maximum of ${SEEN} Lines"
				break
			fi 
			#get video file location (e.g. test, val, train)
			IFS="/" read -r -a FARR <<< $FILE
			FILE="${FARR[-1]}"

			#set the string delimiter to "_" to break up each line into an array
			IFS="_" read -r -a ARR <<< $L

			#set video ID
			ID=${ARR[0]} 

			#set clip start time $IN
			if [[ "${ARR[1]}" =~ [1-9] ]]; then
				#if clip start time > 0, trip padded 0s
				IN=${ARR[1]#"${ARR[1]%%[!0]*}"}
			else
				#if clip start time == 0, set input to 0
				IN=0
			fi

			#set clip end time $OUT
			if [[ "${ARR[2]}" =~ [1-9] ]]; then
				#if clip end time > 0, trip padded 0s
				OUT=${ARR[2]#"${ARR[2]%%[!0]*}"} 			
			else 
				#if clip end time == 0, set input to 0
				OUT=0
			fi

			#clip duration is clip end time - clip start time $LN
			LN=$((${OUT}-${IN}))

			#set expected file name
			NAME=$VIDS/"${FILE}.${ID}.mp4"

			#for every video, download from given timeframe
			YTDL_FAIL=false			
			echo "Starting Download ${ID}: ${SEEN}/${MAX}"

			#access and download whole video with youtube-dl
			#youtube-dl -f mp4/bestvideo captures video and audio in the best accessible format
			#youtube-dl -q shows no output
			youtube-dl "${ID}" -f mp4/bestvideo --external-downloader ffmpeg -o "${NAME}" || true; YTDL_FAIL=true

			#if the download doesn't complete or an error is returned, skip and increment error count
			if [[ $YTDL_FAIL ]]; then
				echo "-----------------------------------YT-DL FAILED VIDEO ${ID}"
				((ERR+=1))
			else 
				echo "-----------------------------------YT-DL DOWNLOADED VIDEO ${ID}"

				FF_FAIL=false

				#trim and encode video clip
				#if the encoding doesn't complete or an error is returned, skip and increment error count
				#ffmpeg -loglevel 8 only shows errors that break the download process
				ffmpeg -ss $IN -t $LN -i $NAME || true; FF_FAIL=true


				if [[ $FF_FAIL ]]; then 
					((ERR+=1))
					echo "-----------------------------------FFMPEG FAILED VIDEO ${ID}"
				else
					echo "-----------------------------------FFMPEG TRIMMED VIDEO ${ID}"
					((SEEN+=1))
				fi	
			fi
					
		done < $FILE
		echo "--Videos Downloaded in ${FILE}: ${SEEN}"
		echo "--Videos Skipped in ${FILE}: ${ERR}"
		((ERR_ALL+=ERR))
		
	done
	echo ""
	echo "--Total Videos Downloaded: ${SEEN}"
	echo "--Total Videos Skipped: ${ERR_ALL}"
}

if [ -z $1 ]; then
	#dw_all
	test $1
else
	download_select $1
fi
