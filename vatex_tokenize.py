import json
import jieba
from nltk.tokenize import word_tokenize
import os

#raw_path = str(os.path.abspath("../raw/") + "/")
raw_path = "C:/Users/bowen/OneDrive/Desktop/ZH-EN-mmt/raw/"

#tok_path = str(os.path.abspath("../tok/") + "/")
tok_path = "C:/Users/bowen/OneDrive/Desktop/ZH-EN-mmt/tok/"

out_files = ["train", "val", "test"]
langs = ["en", "zh"]

print("Caching Directories:")
dirs = {}
#for each listing in raw directory, save if it is a subdirectory
for item in os.listdir(raw_path):
    if os.path.isdir(os.path.join(raw_path, item)):
        print("--", item)
        item = item.split(".")[0]
        dirs[item] = []

print("Collecting Captions:")
for vdir in dirs.keys():
    print("--", vdir)
    v_path = os.path.join(raw_path, str(vdir+".ids.vids"))
    for video in os.listdir(v_path):
        dirs[vdir].append(video)

formatted = {}
for file in out_files:
    formatted[file] = {"en":[], "zh":[]}
    with open (raw_path + file + ".cap.json", encoding="utf-8") as f:
        data = json.load(f)
        
        for videoID in data:            
            if str(file + ".ids." + videoID.split("=")[0] + ".mp4") in dirs[file]:
                formatted[file]["en"] += data[videoID]["en"]
                formatted[file]["zh"] += data[videoID]["zh"]

#tokenize, remove cases, and save to /tok directory
print("Tokenizing:")
jieba.initialize()
jieba.setLogLevel(20)

for file in out_files:
    for lang in langs:
        #output captions to file and tokenize
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
