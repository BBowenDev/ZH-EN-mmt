#!/bin/bash
FV=$(pwd)
FLAG=""

#check positional arguments:
#$1 <pretrain/new>: if pretrain, use pretrained zh-en dynamicconv model; elif new, create new model
if [ -z $1 ]; then
	echo "Usage: preprocess.sh (pretrain/new)"
	echo "--Select pretrain to use a pretrained model"
	echo "--Select new to create a new model"
	exit 0
else
	case $1 in 
		-h) #-h for help
			echo "Usage: preprocess.sh (pretrain/new)"
			echo "--Select pretrain to use a pretrained model"
			echo "--Select new to create a new model"
			exit 0
			;;
		-p) #-p to use pretrained features
			echo "Preparing Pretrained Model"
			FLAG="pretrain"
			;;
		-n)#-n to train new features and vocabularies
			echo "Preparing New Model"
			FLAG="new" 
			;;
		*)
			echo "Usage: preprocess.sh (pretrain/new)"
			echo "--Select pretrain to use a pretrained model"
			echo "--Select new to create a new model"
			exit 0
			;;
	esac
fi

echo "Formatting Directories"
#format directories
if [ ! -d "${FV}/models" ]; then
	mkdir $FV/models
fi

if [ ! -d "${FV}/vatex" ]; then
	#create vatex folders
	mkdir $FV/vatex
	mkdir $FV/vatex/scripts
	mkdir $FV/vatex/raw
	mkdir $FV/vatex/tok
	mkdir $FV/vatex/bpe
	mkdir $FV/vatex/vocab
	mkdir $FV/vatex/feats
fi

VATEX=$FV/vatex
RAW=$VATEX/raw
FEATS=$VATEX/feats

#check CUDA installation/version (10.2 required)
CV=$(nvcc --version)
#if [ "${CV}" != *"release 10.2"* ]; then
#	echo "Installing CUDA 10.2"
#	apt-get install cuda-10-2 &
#	wait
#fi

#if the external intallations directory (fairseq, apex) does not exist, install both
if [ ! -d "${FV}/external" ]; then 
	#create missing directories
	mkdir $FV/external
	
	#install fairseq
	echo "Installing Fairseq"
	cd $FV/external
	git clone https://github.com/pytorch/fairseq &
	echo "Installing Apex"
	git clone https://github.com/NVIDIA/apex &
	wait

	cd $FV/fairseq
	git submodule update --init --recursive
	
	cd $FV/apex
	python setup.py install --cuda_ext --cpp_ext
	
	pip install fairseq &
	pip install apex &
	wait
fi

#if the "pretrain" option is selected, then download pretrained data & pretrained features
if [ $1 == *"pretrain"* ]; then
	echo "Installing Pretrained Model dynamicconv.glu.wmt17.zh-en"
	cd $FV
	#dynamicconv.glu.wmt17.zh-en
	wget "https://dl.fbaipublicfiles.com/fairseq/models/dynamicconv/wmt17.zh-en.dynamicconv-glu.tar.gz"
	mv dict.* $VATEX/vocab
	mv *.code $VATEX/bpe
	mv bpecodes $VATEX/bpe
	mv model.pt $FV/models

	echo "Fetching Pretrained Features"
	wget "https://vatex-feats.s3.amazonaws.com/trainval.zip" -P $FEATS &
	wget "https://vatex-feats.s3.amazonaws.com/public_test.zip" -P $FEATS &
	wait

#if the "new" option is selected, download raw data and install relevant libraries
elif [ $1 == *"new"* ]; then
	echo "Installing subword-nmt"
	cd $FV
	git clone https://github.com/rsennrich/subword-nmt
	
	echo "Installing youtube-dl"
	cd $FV
	git clone https://github.com/ytdl-org/youtube-dl.git
	
	#get raw captions
	echo "Fetching Datasets"
	wget "https://eric-xw.github.io/vatex-website/data/vatex_training_v1.0.json" -P $RAW &
	wget "https://eric-xw.github.io/vatex-website/data/vatex_validation_v1.0.json" -P $RAW &
	wait
fi

echo "Installing Prerequisites"
#install pip requirements from requirements.txt
cd $FV
pip install requirements.txt
