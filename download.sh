#!/bin/bash

FV=$(pwd)
RAW=$FV/vatex/raw
VIDS=$RAW/vids

function show_help {
	echo "Usage: download.sh -arg val"
	echo "Usage: download.sh"
	echo "--Use -a to fetch all available videos from each set (or use no arguments)"
	echo "--Use -s <n> to fetch the first n available videos from the test set"
	echo "--Use -r <train/val/test> to fetch a random available video from the selected set"
	exit 0
}

function download_all {
	echo "Downloading All videos"
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

				#trim and encode video clip
				#ffmpeg -nostdin prevents reading from STDIN, which causes errors with $ bash read
				#ffmpeg -loglevel 8 only shows errors that break the download process
				
				#if the encoding doesn't complete or an error is returned, skip and increment error count
				if (ffmpeg -nostdin -loglevel 8 -ss $IN -t $DR -i $NAME -c:v copy -c:a copy -y $SVNAME); then 
					
					#remove unencoded file
					rm $NAME
					((SEEN+=1))
				else
					((ERR+=1))
				fi	
			else 
				((ERR+=1))
			fi
					
		done < $F_FILE
		echo "--Videos Downloaded in ${FILE}: ${SEEN}"
		echo "--Videos Skipped in ${FILE}: ${ERR}"
		((SEEN_ALL+=SEEN))
		((ERR_ALL+=ERR))
		
	done
	echo ""
	echo "Total Videos Downloaded: ${SEEN_ALL}"
	echo "Total Videos Skipped: ${ERR_ALL}"
}

function download_select {
	echo "Downloading ${1} videos from test set"
	MAX=$1
	SEEN=0
	ERR=0
	I_FILE="test.ids"
	FILE="${I_FILE}.sel"
	
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

			#trim and encode video clip
			#ffmpeg -nostdin prevents reading from STDIN, which causes errors with $ bash read
			#ffmpeg -loglevel 8 only shows errors that break the download process

			#if the encoding doesn't complete or an error is returned, skip and increment error count
			if (ffmpeg -nostdin -loglevel 8 -ss $IN -t $DR -i $NAME -c:v copy -c:a copy -y $SVNAME); then 
				#remove unencoded file
				rm $NAME
				((SEEN+=1))
			else
				((ERR+=1))
			fi	
		else 
			((ERR+=1))
		fi

	done < $I_FILE
	if [[ $SEEN -gt $MAX ]]; then 
		echo "Seen a Maximum of ${SEEN} Lines"
		echo "--Videos Downloaded to ${FILE}: ${SEEN}"
		echo "--Videos Skipped in ${FILE}: ${ERR}"
	fi
}

function download_random {
	echo "Downloading random available video"
	I_FILE="${1}.ids"
	FILE="${I_FILE}.rand"
	
	MAX=1
	SEEN=0
		
	if [[ ! -d $RAW/"${FILE}.vids" ]]; then
		mkdir $RAW/"${FILE}.vids"
	fi
	#target output folder to storage
	OUTDIR=$RAW/"${FILE}.vids"

	#get random line from selected file
	END=$(wc -l $RAW/"${I_FILE}")
	RAND=$(shuf -i 0-$END -n 1)
	LN=$(sed "${RAND}q;d" $RAW/"${I_FILE}")
	
	while [[ $SEEN -lt $MAX ]]; do
		#set the string delimiter to "_" to break up each line into an array
		IFS="=" read -r -a ARR <<< $LN
		
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

			#trim and encode video clip
			#ffmpeg -nostdin prevents reading from STDIN, which causes errors with $ bash read
			#ffmpeg -loglevel 8 only shows errors that break the download process

			#if the encoding doesn't complete or an error is returned, skip and increment error count
			if (ffmpeg -nostdin -loglevel 8 -ss $IN -t $DR -i $NAME -c:v copy -c:a copy -y $SVNAME); then 
				#remove unencoded file
				rm $NAME
				((SEEN+=1))
			else 
				rm $NAME
				RAND=$(shuf -i 0-$END -n 1)
				LN=$(sed "${RAND}q;d" $RAW/"${I_FILE}")
			fi
		else
			RAND=$(shuf -i 0-$END -n 1)
			LN=$(sed "${RAND}q;d" $RAW/"${I_FILE}")
		fi
	done
	echo "Downloaded Random Video ${NAME}"
}

#check positional arguments
if [ -z $1 ]; then
	download_all
else
	while [[ $# -gt 0 ]]; do
		case "$1" in 
			-h) #help and usage message 
				show_help
				;;
			-a) # download all videos
				download_all
				;;
			-s) #select the first n available videos from the test set
				shift
				if test $# -gt 0; then 
					download_select $1
				else 
					echo "Error in arg -s: <int> num videos r"
					exit 0
				fi
				shift
				;;
			-r) #get random video from selected set
				shift
				if test $# -gt 0; then
					if [[ $1 == *"train"* ]] || [[ $1 == *"val"* ]] || [[$1 == *"test"* ]]; then 
						download_random $1
						shift
					else
						echo "Error in arg -r: <train/val/test> set to fetch random video from"
						exit 0
					fi
				
				else 
					echo "Error in arg -r: <train/val/test> set to fetch random video from"
					exit 0
				fi
				;;
			*) #other args should be ignored
				echo "Error: unexpected arg ${1}"
				show_help
				;;
		esac
	done 
fi
