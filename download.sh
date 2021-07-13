#!/bin/bash

FV=$(pwd)
RAW=$FV/vatex/raw
VIDS=$RAW/vids

function download_all {
	for F_FILE in "$RAW"/*.ids; do 
		echo "remove later"	
	done
}

function download_select {
	echo "Downloading ${1} videos"
	MAX=$1
	SEEN_ALL=0
	ERR_ALL=0
	for F_FILE in "$RAW"/*.ids; do
		SEEN=0
		ERR=0
		
		#get video file location (e.g. test, val, train)
		IFS="/" read -r -a FARR <<< $F_FILE
		FILE="${FARR[-1]}"
		
		if [[ ! -d $RAW/"${FILE}.vids" ]]; then
			mkdir $RAW/"${FILE}.vids"
		fi
		#target output folder to storage
		OUTDIR=$RAW/"${FILE}.vids"
		
		while read -r L; do
			#if the given number of videos has been downloaded, break loop
			if [[ $SEEN -gt $MAX ]]; then 
				break
			fi 
			
			#set the string delimiter to "_" to break up each line into an array
			IFS="=" read -r -a ARR <<< $L
			
			#set video ID
			ID=${ARR[0]}
			#set clip start time $IN
			IN=${ARR[1]}
			#set clip duration $DR
			DR=${ARR[2]}

			#set full video download name
			NAME=$VIDS/"${FILE}.${ID}.mp4"
			#set trimmed video download name
			SVNAME=$OUTDIR/"${FILE}.${ID}.mp4"

			#for every video, download from given time frame	
			echo "Starting Download ${ID}: ${SEEN}/${MAX}"

			#access and download whole video with youtube-dl
			#youtube-dl -f mp4/bestvideo captures video and audio in the best accessible format
			#youtube-dl -q shows no output
			
			#if the download doesn't complete or an error is returned, skip and increment error count
			if (youtube-dl "${ID}" -q -f mp4/bestvideo --external-downloader ffmpeg -o $NAME); then
				echo "YT-DL DOWNLOADED VIDEO ${ID} 🟦"

				#trim and encode video clip
				#ffmpeg -nostdin prevents reading from STDIN, which causes errors with $ bash read
				#ffmpeg -loglevel 8 only shows errors that break the download process
				
				#if the encoding doesn't complete or an error is returned, skip and increment error count
				if (ffmpeg -nostdin -loglevel 8 -ss $IN -t $DR -i $NAME -c:v copy -c:a copy -y $SVNAME); then 
					echo "FFMPEG TRIMMED VIDEO ${ID} 🟩"
					#rm $NAME
					((SEEN+=1))
				else
					((ERR+=1))
					echo "FFMPEG FAILED VIDEO ${ID} 🟥"
				fi	
			else 
				echo "YT-DL FAILED VIDEO ${ID} 🟨"
				((ERR+=1))
			fi
					
		done < $F_FILE
		if [[ $SEEN -gt $MAX ]]; then 
			echo "Seen a Maximum of ${SEEN} Lines"
			echo "--Videos Downloaded in ${FILE}: ${SEEN}"
			echo "--Videos Skipped in ${FILE}: ${ERR}"
			((SEEN_ALL+=SEEN))
			((ERR_ALL+=ERR))
			break
			fi
	done
	echo ""
	echo "--Total Videos Downloaded: ${SEEN_ALL}"
	echo "--Total Videos Skipped: ${ERR_ALL}"
}

if [ -z $1 ]; then
	#dw_all
	test $1
else
	download_select $1
fi
