# ZH-EN-MMT
A multimodal machine translation model from Simplified Chinese (ZH) to English (EN) using the VaTeX dataset and Fairseq.

## Installation

The model will install the necessary prerequisites, but requires:
* Python >= 3.6
* [CUDA](https://developer.nvidia.com/cuda-10.2-download-archive) 10.2
* [wget](https://www.gnu.org/software/wget/)
* [fairseq](https://github.com/pytorch/fairseq)
* [NVIDA apex](https://github.com/NVIDIA/apex)
* [nltk](https://www.nltk.org/index.html)
* [punkt](https://github.com/nltk/nltk/blob/develop/nltk/tokenize/punkt.py)
* [sacremoses](https://github.com/alvations/sacremoses)
* [jieba](https://github.com/fxsjy/jieba)
* [subword-nmt](https://github.com/rsennrich/subword-nmt)
* [youtube-dl](https://github.com/ytdl-org/youtube-dl)
* [ffmpeg](https://ffmpeg.org/ffmpeg.html#Synopsis)

Clone the repository to begin installation:
```
git clone https://github.com/BraedenLB/ZH-EN-mmt.git
```

### Preparation
The `prepare.sh` script installs necessary packages and downloads necessary files. The script contains a number of arguments:
* `-p` | to download pre-extracted visual features and BPE codes 
* `-n` | to download the raw VaTeX dataset to create a new model and BPE codes

## Using a Pre-Built Model
This model includes functionality to train on pre-extracted VaTeX visual features and BPE codes. Using the `-p` flag in the [`prepare.sh`](prepare.sh) script will format the model to utilize pretrained features and preprocessed dictionaries. Depending on shell permissions, the script may need to be elevated with `chmod 755`.

```
cd ZH-EN-mmt
#chmod 755 prepare.sh
bash prepare.sh -p
```



### Quick Build
The "quick build" option foregoes explanation and customizability in favor of fast results. Use the code blocks below to quicky train on pre-extracted features.

```
cd ZH-EN-mmt
git clone https://github.com/BraedenLB/ZH-EN-mmt.git
prepare.sh -p
preprocess.sh -m 30000 -t 1000

```
Once preprocessing has completed, use `fairseq` to train using the downloaded features and BPE codes.
```
FAIRSEQ COMMANDS HERE ~~~~~~~~
FAIRSEQ COMMANDS HERE ~~~~~~~~
FAIRSEQ COMMANDS HERE ~~~~~~~~
```


### In-Depth Build

```
cd ZH-EN-mmt
#chmod 755 preprocess.sh
preprocess.sh -m 30000 -t 1000
```



## Training a New Model
**_NOTE: new model training does not currently work, but will be patched in forthcoming builds._**

### Quick Train
The "quick train" option foregoes explaination and customizability in favor of fast results. Use the code blocks below to quikcly download, extract features, and train.

```
cd ZH-EN-mmt
git clone https://github.com/BraedenLB/ZH-EN-mmt.git
prepare.sh -n
preprocess.sh -m 10000 -t 1000
download.sh -a
```


### In-Depth Training



A new model can be trained using the `-n` flag in the [`prepare.sh`](prepare.sh) script. This downloads necessary packages for BPE encoding and multilingual tokenization, as well as the original .JSON VaTeX caption dataset.

```
cd ZH-EN-mmt
#chmod 755 prepare.sh
bash prepare.sh -n
```

## Downloading The Dataset

The `download.sh` script downloads raw video and audio files from YouTube with [youtube-dl](https://github.com/ytdl-org/youtube-dl) and encodes and trims them with [ffmpeg](https://ffmpeg.org/ffmpeg.html#Synopsis) using Alexander Refsum Jensenius's [method](https://www.arj.no/2018/05/18/trimvideo/). Video IDs and clip durations are formatted from the raw dataset with the `vatex_preprocess.py` script. The `download.sh` script contains a number of flags and arguments: 
* `-a` _(or no flags)_ | downloads all available videos from all sets
* `-a` _id_ | downloads all videos after given ID
* `-t` _n_ | fetches the first _n_ available videos from the test set built with `vatex_preprocess.py`
* `-s` _set_ | fetches all videos from _set_ specified set (train/val/test)
* `-r` _set_ | fetches the first available video from _set_ specified set (train/val/test)
* `-h` | show above usage information

Downloads from the `-t` and `-r` flags will be placed in marked subfolders to prevent errors with downloading the whole dataset.


```
cd ZH-EN-mmt
#chmod 755 prepare.sh
bash download.sh -a
```

_**NOTE:**_ as the VaTeX dataset is sourced from YouTube, not all videos will still be available or accessible. Inaccessible videos will be annotated and ignored.


### Preprocessing
	
	
	

</details>
