#!/bin/bash
FV=$(pwd)
RAW=$FV/vatex/raw

#remove the vids temp folder
rm -R $RAW/vids

#learn bpe for each downloaded video
python3 $FV/vatex/scripts/learn_bpe.py
