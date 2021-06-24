#!/bin/bash

FV=$(pwd)

#check positional arguments:
#$1 <pretrain/new>: if pretrain, use pretrained zh-en dynamicconv model; elif new, create new model

if [ -z $1 ]; then
	echo "Usage: preprocess.sh (pretrain/new)"
	echo "--Select pretrain to use a pretrained model"
	echo "--Select new to create a new model"
	exit 0
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
	mkdrir $FV/vatex/raw
	mkdir $FV/vatex/tok
	mkdir $FV/vatex/bpe
	mkdir $FV/vatex/vocab
fi
VATEX=$FV/vatex

#check CUDA installation/version (10.2 required)
CV = $(nvcc --version)
if [ "${CV}" != *"release 10.2"* ]; then
	echo "Installing CUDA 10.2"
	apt-get install cuda-10-2 &
	wait
fi

if [ ! -d "${FV}/external" ]; then 
	#create missing directories
	mkdir $FV/external
	
	#install fairseq
	echo "Installing Fairseq"
	cd $FV/external
	git clone https://github.com/pytorch/fairseq
	cd fairseq
	git submodule update --init --recursive
	pip install fairseq &
	wait
	
	#install apex
	echo "Installing Apex"
	cd $FV/external
	git clone https://github.com/NVIDIA/apex
	cd apex
	python setup.py install --cuda_ext --cpp_ext --pyprof
	pip install apex &
	wait
fi

#if the "pretrain" option is selected, then download pretrained data
if [ $1 == *"pretrain"* ]; then
	
	echo "Installing pretrained model dynamicconv.glu.wmt17.zh-en"
	#dynamicconv.glu.wmt17.zh-en
	wget https://dl.fbaipublicfiles.com/fairseq/models/dynamicconv/wmt17.zh-en.dynamicconv-glu.tar.gz
	mv dict.* $VATEX/vocab
	mv *.code $VATEX/bpe
	mv bpecodes $VATEX/bpe
	mv model.pt $FV/models

elif [ $1 == *"new"* ]; then
	echo "Installing subword-nmt"
	#install subword-nmt
	cd $FV
	git clone https://github.com/rsennrich/subword-nmt
else; then
	echo "Usage: preprocess.sh (pretrain/new)"
	echo "--Select pretrain to use a pretrained model"
	echo "--Select new to create a new model"
	exit 0
fi

echo "Installing Prerequisites"
#install pip requirements
requirements.txt | while read line; do 
	echo "--${line}"
	pip install $line &
done
