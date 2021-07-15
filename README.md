# ZH-EN-MMT
A multimodal machine translation model from Simplified Chinese (ZH) to English (EN) using the VaTeX dataset and Fairseq.

## Installation

```
git clone https://github.com/BraedenLB/ZH-EN-mmt.git
```

	
## Using a Pretrained Model
By default, this model functions on pretrained VaTeX video features and preprocessed caption data. Using the `-p` flag in the [`prepare.sh`](prepare.sh) script will format the model to utilize pretrained features and preprocessed dictionaries. Depending on shell permissions, the script may need to be elevated with `chmod 755`.


### Quick Build

```
cd ZH-EN-mmt
git clone https://github.com/BraedenLB/ZH-EN-mmt.git
prepare.sh -p
preprocess.sh -m 10000 -t 1000

```


### In-Depth Build

```
cd ZH-EN-mmt
#chmod 755 prepare.sh
bash prepare.sh -p
```

## Training a New Model
**_NOTE_**: new model training does not currently work, but will be patched in forthcoming builds.

### Quick Train

```
cd ZH-EN-mmt
git clone https://github.com/BraedenLB/ZH-EN-mmt.git
prepare.sh -p
preprocess.sh -m 10000 -t 1000
download.sh -a
```


### In-Depth Train



A new model can be trained using the `-n` flag in the [`prepare.sh`](prepare.sh) script.







```
cd ZH-EN-mmt
#chmod 755 prepare.sh
bash prepare.sh -n
```

## Downloading The Dataset

The `download.sh` script downloads raw video and audio files from YouTube with [youtube-dl](https://github.com/ytdl-org/youtube-dl) and encodes and trims them with [ffmpeg](https://ffmpeg.org/ffmpeg.html#Synopsis) using Alexander Refsum Jensenius's [method](https://www.arj.no/2018/05/18/trimvideo/). Video IDs and clip durations are formatted from the raw dataset with the `vatex_preprocess.py` script. The `download.sh` script contains a number of flags and arguments: 
* `-a` _(or no flags)_ | downloads all available videos
* `-s` _n_ | fetches the first _n_ available videos from the test set built with `vatex_preprocess.py`
* `-r` _set_ | fetches the first available video from _set_ specified set (train/val/test)
* `-h` | show above usage information

```
cd ZH-EN-mmt
#chmod 755 prepare.sh
bash download.sh -a
```


### Preprocessing
	
	
	

</details>
