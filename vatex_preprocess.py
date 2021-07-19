import argparse
import json
import jieba
import nltk
import datetime
from nltk.tokenize import word_tokenize
import os

'''
#data structure
formatted = {
    "ID1": {"en": ["cap1", "cap2"...],
           "zh": ["cap1", "cap2"...], }
    "ID2": {}...
    }
'''

raw_path = str(os.path.abspath("../raw/") + "/")

tok_path = str(os.path.abspath("../tok/") + "/")

jsons = ["vatex_training_v1.0", "vatex_validation_v1.0"]
out_files = ["train", "val", "test"]
langs = ["en", "zh"]

#format listed sentences from raw json data             
formatted = {}
ids = {}

parser = argparse.ArgumentParser(description="A preprocessing script to tokenize the VaTeX dataset.")
parser.add_argument("-f", "--full", dest="full", default=False, 
                    help="True if using the full dataset | False if only using parallel translations")
parser.add_argument("-p", "--pretrain", dest="pretrain", default=False,
                    help="True if using a pretrained model | False if building a new model")
parser.add_argument("-t", "--test_size", dest="test_size", type=int, default=1000, 
                    help="Number of videos removed from the train/val sets to create test set. | default 1000 | minimum 1 | maximum 5999")

args = parser.parse_args()
args.full = bool(args.full)
args.pretrain = bool(args.pretrain)
args.test_size = int(args.test_size)

if args.test_size > 5999 or args.test_size < 1:
    raise argparse.ArgumentError("Maximum test size of 5,999 videos")
    quit()

#if nltk has never been used, run line:
nltk.download("punkt")


def get_timestamp(raw_dict):
    vid = [""]
    vid[0] = raw_dict["videoID"][0:11]
    vid += raw_dict["videoID"][12:].split("_")
    
    vid[1] = datetime.timedelta(seconds = int(vid[1]))
    vid[2] = datetime.timedelta(seconds = int(vid[2]))
    
    #calculate clip duration
    vid[2] = (str(vid[2] - vid[1]))
    vid[1] = str(vid[1])

    vid = "=".join(vid)
    
    return vid

def parse_new():
    print("Reading:")
    for num, data_file in enumerate(jsons):
        with open(raw_path + data_file + ".json") as f:
            data = json.load(f)
            
            data_type = out_files[jsons.index(data_file)]
            ids[data_type] = []       
            vtx_dict = {}
            
            print("--", data_file)
            for raw_dict in data:
                #format video start and stop time for later use
                vid = get_timestamp(raw_dict)
                
                #save videoID as key for captions
                vtx_dict[vid] = {"en":[], "zh":[]}
                ids[data_type].append(vid)
                
                if "enCap" in raw_dict.keys():
                    if args.full is True: #if using the full dataset, don't truncate
                        vtx_dict[vid]["en"] += raw_dict["enCap"]
                    else: #otherwise, truncate dataset to parallel captions only
                        vtx_dict[vid]["en"] += raw_dict["enCap"][-5:]
                
                if "chCap" in raw_dict.keys():
                    if args.full is True: #if using the full dataset, don't truncate
                        vtx_dict[vid]["zh"] += raw_dict["chCap"]
                    else: #otherwise, truncate dataset to parallel captions only
                        vtx_dict[vid]["zh"] += raw_dict["chCap"][-5:]
                    
            formatted[data_type] = vtx_dict

    #create small test set from val and train set
    ids_half = int(args.test_size/2)

    #create for captions and ids
    formatted["test"] = {}
    ids["test"] = []
    
    #move n/2 captions from train set into test set
    for num, i in enumerate(formatted["train"]):
        if num < ids_half:
            formatted["test"][i] = formatted["train"][i]
        
    num = 0
    fmt = {}
    for i in formatted["train"]:
        if num >= ids_half:
            fmt[i] = formatted["train"][i]
        num += 1
    formatted["train"] = fmt
   
    #move n/2 clip durations from train ids to test ids
    ids["test"] += ids["train"][:ids_half]
    ids["train"] = ids["train"][ids_half:]
    
    #move n/2 captions from train set into test set
    fmt = formatted["val"]
    for num, i in enumerate(fmt):
        if num < ids_half:
            formatted["test"][i] = formatted["val"][i]     
    
    num = 0
    fmt = {}
    for i in formatted["val"]:
        if num >= ids_half:
            fmt[i] = formatted["val"][i]
        num += 1
    formatted["val"] = fmt

    #move n/2 clip durations from val ids to test ids
    ids["test"] += ids["val"][:ids_half]
    ids["val"] = ids["val"][ids_half:]
    
    #output video ids and clip durations
    print("Writing:")
    for file in out_files:
        #output captions to json for access through `learn_bpe.py` script
        with open(raw_path + file + ".cap" + ".json", "w", encoding="utf-8") as f:
            print("--", file + ".json")
            json.dump(formatted[file], f)
            
        #output ids to .ids file for access through `download.sh` script
        with open(raw_path + file + ".ids", "w", encoding="utf-8") as l:
            print("--", file + ".ids")
            for line in ids[file]:
                l.write(line + "\n")
         
#if a preprocessed model is used, tokenize and BPE encode all captions
def parse_preprocessed(): 
    print("Reading:")
    for num, data_file in enumerate(jsons):        
        with open(raw_path + data_file + ".json") as f:
            print(data_file + ".json" + " opening")
            data = json.load(f)
        
        vtx_dict = {"en": [], "zh": []}
        
        print("--", data_file)
        for raw_dict in data:
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
    
    #create for captions
    formatted["test"] = {"en": [], "zh": []}
    formatted["test"]["en"] = formatted["val"]["en"][-caps_half:]
    formatted["test"]["zh"] = formatted["val"]["zh"][-caps_half:]
    formatted["test"]["en"].extend(formatted["test"]["en"][-caps_half:])
    formatted["test"]["zh"].extend(formatted["test"]["zh"][-caps_half:])
    
    #remove newly duplicated captions from original locations
    del formatted["val"]["en"][-caps_half:]
    del formatted["val"]["zh"][-caps_half:]
    del formatted["train"]["en"][-caps_half:]
    del formatted["train"]["zh"][-caps_half:]
    
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

#if pretrain option is selected, tokenize/BPE encode all data
#otherwise, preprocess for downloading
if args.pretrain is True:
    parse_preprocessed()
else:
    parse_new()
