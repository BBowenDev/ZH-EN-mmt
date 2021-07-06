import argparse
import json
import jieba
import nltk
from nltk.tokenize import word_tokenize
import os

parser = argparse.ArgumentParser(description="A preprocessing script to tokenize the VaTeX dataset.")
parser.add_argument("-f", "--full", dest="full", default=False, 
                    help="True if using the full dataset | False if only using parallel translations")
parser.add_argument("-t", "--test_size", dest="test_size", type=int, default=1000, 
                    help="Number of videos removed from the train/val sets to create test set. | default 1000 | minimum 1 | maximum 5999")
args = parser.parse_args()
args.full = bool(args.full)
args.test_size = int(args.test_size)

if args.test_size > 5999 or args.test_size < 1:
    raise argparse.ArgumentError("Maximum test size of 29,9999")
    quit()

#if nltk has never been used, run line:
nltk.download("punkt")

raw_path = str(os.path.abspath("../ZH-EN-mmt/raw/") + "/")
print(raw_path)
tok_path = str(os.path.abspath("../ZH-EN-mmt/tok/") + "/")

jsons = ["vatex_training_v1.0", "vatex_validation_v1.0"]
out_files = ["train", "val", "test"]
langs = ["en", "zh"]

#format listed sentences from raw json data             
formatted = {}
ids = {}

#format video ids container
for file in out_files:
    ids[file] = []

print("Reading:")
for num, data_file in enumerate(jsons):        
    with open(raw_path + data_file + ".json") as f:
        print(data_file + ".json" + " opening")
        data = json.load(f)
    
    data_type = out_files[jsons.index(data_file)]
    
    vtx_dict = {"en": [], "zh": []}
    
    print("--", data_file)
    for raw_dict in data:
        #add video ID to later list
        ids[data_type].append(raw_dict["videoID"])
        
        if "enCap" in raw_dict.keys():
            if args.full is True: #if using the full dataset, don't truncate
                vtx_dict["en"] += raw_dict["enCap"]
            else: #otherwise, truncate dataset to parallel captions only
                vtx_dict["en"] += raw_dict["enCap"][-5:]
        
        if "chCap" in raw_dict.keys():
            if args.full is True: #if using the full dataset, don't truncate
                vtx_dict["zh"] += raw_dict["chCap"]
            else: #otherwise, truncate dataset to parallel captions only
                vtx_dict["zh"] += raw_dict["chCap"][-5:]
                
    formatted[out_files[num]] = vtx_dict

#create small test set from val and train set
if args.full is True:
    caps_half = int((args.test_size*10)/2)
else:
    caps_half = int((args.test_size*5)/2)
ids_half = int(args.test_size/2)

#create for captions
formatted["test"] = {"en": [], "zh": []}
formatted["test"]["en"] = formatted["val"]["en"][-caps_half:]
formatted["test"]["zh"] = formatted["val"]["zh"][-caps_half:]
formatted["test"]["en"].extend(formatted["test"]["en"][-caps_half:])
formatted["test"]["zh"].extend(formatted["test"]["zh"][-caps_half:])

#create for video ids
ids["test"] = ids["val"][-ids_half:]
ids["test"].extend(ids["test"][-ids_half:])

#remove newly duplicated captions from original locations
del formatted["val"]["en"][-caps_half:]
del formatted["val"]["zh"][-caps_half:]
del formatted["train"]["en"][-caps_half:]
del formatted["train"]["zh"][-caps_half:]

#remove newly duplicated video ids from original locations
del ids["val"][-ids_half:]
del ids["train"][-ids_half:]

#tokenize, remove cases, and save to /tok directory
print("Tokenizing:")
jieba.initialize()
jieba.setLogLevel(20)

for file in out_files:
    for lang in langs:
            #output captions to file
            with open(tok_path + file + "_tok" + "." + lang, "w", encoding="utf-8") as f:
                print("--", file + "." + lang)
                
                if lang == "en":       
                    for line in formatted[file][lang]:
                        words = word_tokenize(line.lower()) #tokenize English with nltk
                        words = " ".join(words)
                        f.write(words + "\n") 
                
                elif lang == "zh":
                    for line in formatted[file][lang]:
                        words = jieba.lcut(line, cut_all=True) #tokenize Chinese with jieba
                        words = " ".join(words)
                        f.write(words + "\n")
    
    #output video ids to file
    with open(raw_path + file + ".ids", "w", encoding="utf-8") as l:
        print("--", file + ".ids")
        for line in ids[file]:
            l.write(line + "\n")
