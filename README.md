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

## Using a Pre-Built Model
This model includes functionality to train on pre-extracted VaTeX visual features and BPE codes. Using the `-p` flag in the `prepare.sh` script will format the model to utilize pretrained features and preprocessed dictionaries. Depending on shell permissions, the script may need to be elevated with `chmod 755`.

### Quick Build
The "quick build" option foregoes explanation and customizability in favor of fast results. Use the code blocks below to quicky train on pre-extracted features.

```
git clone https://github.com/BraedenLB/ZH-EN-mmt.git
cd ZH-EN-mmt
bash prepare.sh -p
bash preprocess.sh -m 30000 -t 1000
```
```
FAIRSEQ COMMANDS HERE ~~~~~~~~
FAIRSEQ COMMANDS HERE ~~~~~~~~
FAIRSEQ COMMANDS HERE ~~~~~~~~
```

### In-Depth Build

```
#chmod 755 prepare.sh
bash prepare.sh -n
```
```
#chmod 755 preprocess.sh
bash preprocess.sh -m 30000 -t 1000
```
```
FAIRSEQ COMMANDS HERE ~~~~~~~~
FAIRSEQ COMMANDS HERE ~~~~~~~~
FAIRSEQ COMMANDS HERE ~~~~~~~~
```

## Training a New Model
**_NOTE: new model training does not currently work, but will be patched in forthcoming builds._**

### Quick Train
The "quick train" option foregoes explaination and customizability in favor of fast results. Use the code blocks below to quikcly download, extract features, and train.

```
git clone https://github.com/BraedenLB/ZH-EN-mmt.git
cd ZH-EN-mmt
bash prepare.sh -n
bash preprocess.sh -m 10000 -t 1000
bash download.sh -a
```
```
EXTRACT.SH HERE ~~~~~~~~
EXTRACT.SH HERE ~~~~~~~~
```
```
FAIRSEQ COMMANDS HERE ~~~~~~~~
FAIRSEQ COMMANDS HERE ~~~~~~~~
FAIRSEQ COMMANDS HERE ~~~~~~~~
```

### In-Depth Training
#### Prepare
A new model can be trained using the `-n` flag in the [`prepare.sh`](prepare.sh) script. This downloads necessary packages for BPE encoding and multilingual tokenization, as well as the original .JSON VaTeX caption dataset.

```
#chmod 755 prepare.sh
bash prepare.sh -n
```

#### Preprocess
Once necessary packages are installed, use the `preprocessing.sh` script to prepare the VaTeX dataset for downloads.
```
#chmod 755 preprocess.sh
bash preprocess.sh -m 30000 -t 1000
```

#### Download
Once preprocessing has completed, use the `download.sh` script to download the full dataset. The script downloads should download an average of 90-100 videos per hour. 
_**NOTE:**_ as the VaTeX dataset is open-sourced from YouTube, not all videos will still be available or accessible. Inaccessible videos will be annotated and ignored, and captions for inaccessible videos will not be used in BPE encoding or training.
```
#chmod 755 download.sh
bash download.sh -a
```

#### Extract
Once the dataset download has completed, use the `extract.sh` script to extract visual features and activities.
```
EXTRACT.SH HERE ~~~~~~~~
EXTRACT.SH HERE ~~~~~~~~
```

#### Train
Once feature extraction has completed, use `fairseq` to train using the extracted features and BPE codes.
```
FAIRSEQ COMMANDS HERE ~~~~~~~~
FAIRSEQ COMMANDS HERE ~~~~~~~~
FAIRSEQ COMMANDS HERE ~~~~~~~~
```

## Preparing The Dataset
The [`prepare.sh`](prepare.sh) script installs necessary packages and downloads necessary files, including [fairseq](https://github.com/pytorch/fairseq) and NVIDIA's [apex](https://github.com/NVIDIA/apex). The `prepare.sh` script contains 3 combinations of flags:
* `-p` | to download pre-extracted visual features and BPE codes 
* `-n` | to download the raw VaTeX dataset to create a new model and BPE codes
* `-h` | show above usage information

## Preprocessing The Dataset
The [`preprocess.sh`](preprocess.sh) script calls the [`learn_bpe.sh`](learn_bpe.sh), [`vatex_preprocess.py`](vatex_preprocess.py), and [`vatex_tokenize.py`](vatex_tokenize.py) scripts to tokenize and BPE encode caption data in the VaTeX dataset. English tokenization is performed by [nltk](https://www.nltk.org/index.html) and Chinese tokenization is performed by [jieba](https://github.com/fxsjy/jieba). BPE encoding for both languages is performed by [subword-nmt](https://github.com/rsennrich/subword-nmt). Additionally, as a cross-lingual testing set is not available from the original VaTeX dataset, the script also creates the test set from the training and validation sets. 

The `preprocess.sh` script contains 3 combinations of flags and arguments:
* `-m` _n_ | performs _n_ merges in BPE encoding
* `-t` _n_ | creates a training set of videos of maximum size _n_
* `-h` | show above usage information

## Downloading The Dataset
The [`download.sh`](download.sh) script downloads raw video and audio files from YouTube with [youtube-dl](https://github.com/ytdl-org/youtube-dl) and encodes and trims them with [ffmpeg](https://ffmpeg.org/ffmpeg.html#Synopsis) using Alexander Refsum Jensenius's [method](https://www.arj.no/2018/05/18/trimvideo/). Video IDs and clip durations are formatted from the raw dataset with the [`vatex_preprocess.py`](vatex_preprocess.py) script. _On average, the script can download anywhere from 90 to 100 videos per hour._ 

The `download.sh` script contains 6 combinations of flags and arguments: 
* `-a` _(or no flags)_ | downloads all available videos from all sets
* `-a` _id_ | downloads all videos after given _ID_ (e.g. "-a qwggD_aa3sd")
* `-t` _n_ | fetches the first _n_ available videos from the test set built with `vatex_preprocess.py`
* `-s` _set_ | fetches all videos from _set_ specified set (train/val/test)
* `-r` _set_ | fetches the first available video from _set_ specified set (train/val/test)
* `-h` | show above usage information

Downloads from the `-t` and `-r` flags will be placed in marked subfolders to prevent errors with downloading the whole dataset.

_**NOTE:**_ as the VaTeX dataset is sourced from YouTube, not all videos will still be available or accessible. Inaccessible videos will be annotated and ignored.
