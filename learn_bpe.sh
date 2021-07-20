#!/bin/bash
FV=$(pwd)
SWNMT=$FV/subword-nmt
VT=$FV/vatex
TOK=$VT/tok
RAW=$VT/raw
BPE=$VT/bpe
VOC=$VT/vocab

PRETRAIN=false
MERGES=10000

function show_help {
	echo "--Use no arguments for a new model"
	echo "--Use -p for pretrained models"
	echo "--Use -m <int> to specify the number of merges used in BPE encoding (default 10000)"
	exit 0
}

function python_tokenize {
	if [[ $PRETRAIN = false ]]; then
		#remove vids directory
		rm -R $RAW/vids

		#tokenize data
		python3 $VT/scripts/vatex_tokenize.py
	fi
}

function learn {
	#learn BPE
	#10,000 merge operations are used (can be hyperparamaterized)
	#learning and applying bpe are broken up so they can be parallelized
	echo "Learning BPE:"
	for TYPE in "train" "val" "test"; do
		for LANG in "en" "zh"; do
			INPUT="${TOK}/${TYPE}_tok.${LANG}"
			OUTPUT="${BPE}/${TYPE}.bpe${MERGES}.${LANG}"
			CODES="${TOK}/codes_${LANG}.bpe"
			VOCAB="${VOC}/${TYPE}_vocab.${LANG}"

			echo "-- ${TYPE}-${LANG}"
			python3 $SWNMT/subword_nmt/learn_joint_bpe_and_vocab.py -s $MERGES -o $CODES --input $INPUT --write-vocabulary $VOCAB
		done
	done

	#once all BPE has been learned, it is applied
	echo "Applying BPE:"
	for TYPE in "train" "val" "test"; do
		for LANG in "en" "zh"; do
			INPUT="${TOK}/${TYPE}_tok.${LANG}"
			OUTPUT="${BPE}/${TYPE}.bpe${MERGES}.${LANG}"
			CODES="${TOK}/codes_${LANG}.bpe"
			VOCAB="${VOC}/${TYPE}_vocab.${LANG}"

			echo "-- ${TYPE}-${LANG}"
			python3 $SWNMT/subword_nmt/apply_bpe.py -c $CODES --vocabulary $VOCAB < $INPUT > $OUTPUT
		done
	done
}

#check positional arguments
if [ ! -z $1 ]; then 
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

#tokenize as needed
python_tokenize

#learn BPE
learn
