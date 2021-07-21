#!/bin/bash
FV=$(pwd)

PRETRAIN=false
FULL=false
MERGES=10000
T=1000

function show_help {
	echo "Usage: preprocess.sh -arg val -arg val"
	echo "Use no arguments for default values"
	echo "--Use -p if a pretrained video features model is being used"
	echo "--Use -m to specify the number of merges used in BPE encoding (default 10000)"
	echo "--Use -t to specify the size of the created test set (default 1000 videos)"
	exit 0
}

function proc {
	SWNMT=$FV/subword-nmt
	VT=$FV/vatex
	TOK=$VT/tok
	RAW=$VT/raw
	BPE=$VT/bpe
	VOC=$VT/vocab
	
	echo "Tokenizing dataset"
	if [[ $PRETRAIN = true ]]; then
		#if a pretrained model is being used, preprocess and learn BPE
		python3 $VT/scripts/vatex_preprocess.py -f $FULL -t $T -p true
		bash $FV/learn_bpe.sh -p -m $MERGES
	else 
		#if a new model is being created, preprocess data for downloading WITHOUT learning BPE
		python3 $VT/scripts/vatex_preprocess.py -f $FULL -t $T
	fi
}

#check positional arguments
if [ -z $1 ]; then
	echo "Using Default Values M=10000 | T=1000"
else 
	while test $# -gt 0; do
		case "$1" in 
			-h) #help and ussage message
				show_help
				;;
			-m) #number of merges for BPE
				shift
				if test $# -gt 0; then
					MERGES=${1}
				else 
					echo "Error in arg -m:"
					show_help
				fi
				shift
				;;
			-t) #number of videos in the created test set
				shift
				if test $# -gt 0; then
					T=${1}
				else
					echo "Error in arg -t:"
					show_help
				fi
				shift
				;;
			-f) #boolean if full model caption capacity is to be used 
				shift
				FULL=true
				;;
			-p) #boolean if pretrained model is used
				shift
				PRETRAIN=true
				;;
			*) #other args should be ignored  
				echo "Error: unexpected arg ${1}"
				show_help 
				;;
		esac 
	done
fi

#run preprocessing
proc
