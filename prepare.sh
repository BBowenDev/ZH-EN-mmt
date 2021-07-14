#!/bin/bash
FV=$(pwd)

function show_help {
	echo "Usage: preprocess.sh -arg"
	echo "--Use -p to use a pretrained model (easiest)"
	echo "--Use -n to create a new model (largest)"
	echo "--Use -h for help"
	exit 0
}

#general purpose preparations that apply to most versions of the model
function prep_dirs {
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
		mkdir $FV/vatex/raw/vids
		mkdir $FV/vatex/tok
		mkdir $FV/vatex/bpe
		mkdir $FV/vatex/vocab
		mkdir $FV/vatex/feats
		mv vatex_preprocess.py $FV/vatex/scripts
	fi
}

function prep_all {
	prep_dirs
	VATEX=$FV/vatex
	RAW=$VATEX/raw
	FEATS=$VATEX/feats
	
	#if the external intallations directory (fairseq, apex) does not exist, install both
	if [ ! -d "${FV}/external" ]; then 
		#create missing directories
		mkdir $FV/external

		#check CUDA installation/version (10.2 required)
		#CV=$(nvcc --version)
		#if [ "${CV}" != *"release 10.2"* ]; then
		#	echo "Installing CUDA 10.2"
		#	apt-get install cuda-10-2 &
		#	wait
		#fi

		#install fairseq
		echo "Installing Fairseq"
		cd $FV/external
		git clone https://github.com/pytorch/fairseq &
		#echo "Installing Apex"
		#git clone https://github.com/NVIDIA/apex &
		wait

		cd $FV/external/fairseq
		git submodule update --init --recursive

		#cd $FV/external/apex
		#python setup.py install --cuda_ext --cpp_ext
	fi
	
	echo "Installing General Prerequisites"
	pip install fairseq &
	pip install apex &
	pip install torch &
	pip install subword-nmt &
	pip install sacremoses &
	wait
}

#for a pretrained model, download pretrained data & pretrained features
function prep_pretrain {
	prep_all
	
	echo "Installing Pretrained Model dynamicconv.glu.wmt17.zh-en"
	cd $FV
	#dynamicconv.glu.wmt17.zh-en
	curl -O "https://dl.fbaipublicfiles.com/fairseq/models/dynamicconv/wmt17.zh-en.dynamicconv-glu.tar.gz"
	mv dict.* $VATEX/vocab
	mv *.code $VATEX/bpe
	mv bpecodes $VATEX/bpe
	mv model.pt $FV/models

	echo "Fetching Pretrained Features"
	curl -O $FEATS "https://vatex-feats.s3.amazonaws.com/trainval.zip" &
	curl -P $FEATS "https://vatex-feats.s3.amazonaws.com/public_test.zip" &
	wait
}

#for a new model, download raw data and install relevant libraries
function prep_new {
	prep_all
	
	echo "Installing subword-nmt"
	cd $FV
	git clone https://github.com/rsennrich/subword-nmt
	pip install subword-nmt

	echo "Installing Prerequisites"
	pip install nltk &
	pip install jieba &
	pip install youtube-dl &
	pip install ffmpeg &
	wait
	
	#get raw captions
	echo "Fetching Datasets"
	curl -O $RAW "https://eric-xw.github.io/vatex-website/data/vatex_training_v1.0.json" &
	wget -O $RAW "https://eric-xw.github.io/vatex-website/data/vatex_validation_v1.0.json" &
	wait
}

#check positional arguments:
#$1 : if -p, use pretrained zh-en dynamicconv model; elif -n, create new model
if [ -z $1 ]; then
	show_help
else
	case $1 in 
		-h) #-h for help
			show_help
			;;
		-p) #-p to use pretrained features
			echo "Preparing Pretrained Model"
			prep_pretrain
			;;
		-n)#-n to train new features and vocabularies
			echo "Preparing New Model"
			prep_new
			;;
		*)
			echo "Usage: preprocess.sh -arg"
			echo "--Use -p to use a pretrained model"
			echo "--Use -n to create a new model"
			echo "--Use -h for help"
			exit 0
			;;
	esac
fi
