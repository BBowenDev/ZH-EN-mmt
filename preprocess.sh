#!/bin/bash

if [ ! -z $1 ]; then
  MERGES = $1
else; then
  MERGES = 10000
fi

FV=$(pwd)
SWNMT=$FV/subword-nmt
VT=$FV/vatex
TOK=$VT/tok
RAW=$VT/raw
BPE=$VT/bpe
VOC=$VT/vocab

#run preprocessing script on raw captions, tokenizing and saving to new files
echo "Tokenizing dataset"
cd $VT/scripts
python vatex_preprocess.py -f True -t $MERGES

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
