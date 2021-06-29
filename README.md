# ZH-EN-MMT
A multimodal machine translation model from Simplified Chinese (ZH) to English (EN) using the VaTeX dataset and Fairseq.

## Installation

```
git clone https://github.com/BraedenLB/ZH-EN-mmt.git
```

	
## Using a Pretrained Model
By default, this model functions on pretrained VaTeX video features and preprocessed caption data. Using the `-p` flag in the [`prepare.sh`](prepare.sh) script will format the model to utilize pretrained features and preprocessed dictionaries. Depending on shell permissions, the script may need to be elevated with `chmod 755`.

```
cd ZH-EN-mmt
#chmod 755 prepare.sh
bash prepare.sh -p
```

## Training a New Model
**_NOTE_**: new model training does not currently work, but will be patched in forthcoming builds.


A new model can be trained using the `-n` flag in the [`prepare.sh`](prepare.sh) script.


```
cd ZH-EN-mmt
#chmod 755 prepare.sh
bash prepare.sh -n
```


### Preprocessing
	
	
	

</details>
