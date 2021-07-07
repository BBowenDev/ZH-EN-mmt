#!/bin/bash
FV=$(pwd)

MERGES=0
T=0

function show_help {
	echo "Usage: preprocess.sh -arg val -arg val"
	echo "Required arguments: -m <int> -t <int>"
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
	
	#run preprocessing script on raw captions, tokenizing and saving to new files
	echo "Tokenizing dataset"
	cd $VT/scripts
	python vatex_preprocess.py -f True -t $T

	#10,000 merge operations are used (can be hyperparamaterized)
	#learning and applying bpe are broken up so they can be parallelized
	cd $SWNMT
	echo "Learning BPE:"
	for TYPE in "train" "val" "test"; do
		for LANG in "en" "zh"; do 
			INPUT="${TOK}/${TYPE}_tok.${LANG}"
			OUTPUT="${BPE}/${TYPE}.bpe${MERGES}.${LANG}"
			CODES="${TOK}/codes_${LANG}.bpe"
			VOCAB="${VOC}/${TYPE}_vocab.${LANG}"

			echo "--${TYPE}-${LANG}"
			python $SWNMT/subword_nmt/learn_joint_bpe_and_vocab.py -s $MERGES -o $CODES --input $INPUT --write-vocabulary $VOCAB
		done
	done
	wait

	#once all BPE has been learned, it is applied
	echo "Applying BPE:"
	for TYPE in "train" "val" "test"; do
		for LANG in "en" "zh"; do 
			INPUT="${TOK}/${TYPE}_tok.${LANG}"
			OUTPUT="${BPE}/${TYPE}.bpe${MERGES}.${LANG}"
			CODES="${TOK}/codes_${LANG}.bpe"
			VOCAB="${VOC}/${TYPE}_vocab.${LANG}"

			echo "--${TYPE}-${LANG}"
			python $SWNMT/subword_nmt/apply_bpe.py -c $CODES --vocabulary $VOCAB < $INPUT > $OUTPUT
		done
	done
	wait
}

#check positional arguments
if [ -z $1 ]; then
	MERGES=10000
	T=1000
	exit 0
else 
	
	while test $# -gt 0; do
		case "$1" in 
			-h)#help and ussage message
				show_help
				;;
			-m) #number of merges for BPE (required)
				shift
				if test $# -gt 0; then
					MERGES=${1}
				else 
					echo "Error in arg -m:"
					show_help
					exit 0
				fi
				shift
				;;
			-t) #number of videos in the created test set (required)
				shift
				if test $# -gt 0; then
					T=${2}
				else
					echo "Error in arg -t:"
					show_help
					exit 0
				fi
				shift
				;;
			*)#other args should be ignored  
				echo "Error: unexpected arg ${1}"
				show_help 
				exit 0
				;;
		esac 
	done
fi
