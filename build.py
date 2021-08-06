import argparse
import os
import json
import jieba
from sacremoses import MosesTokenizer
import datetime

#CONSIDER ADDING ARG FOR ENCODING TYPE
parser = argparse.ArgumentParser(description="A preprocessing script to format, prepare, and tokenize the VaTeX dataset.")
parser.add_argument("-f", "--full", dest="full", default=False,
                    help="True if using the full dataset | False if only using parallel translations | default=False")
parser.add_argument("-p", "--pretrain", dest="pretrain", default=False,
                    help="True if using pre-encoded BPE | False if newly encoding BPE | default=False")
parser.add_argument("-t", "--test-size", dest="test_size", type=int, default=1000,
                    help="Number of videos removed from the train/val sets to create a test set. | default=1000 | minimum 1 | maximum 5999")
parser.add_argument("-d", "--for-download", dest="download", default=False,
                    help="True if just ids are being created for dataset downloading | False otherwise | default=False")
parser.add_argument("-k", "--tokenize-only", dest="token", default=False, 
                    help="True if only tokenizing from *.cap.jsons | False otherwise | default=False")

args = parser.parse_args()
args.test_size = int(args.test_size)
args.full = bool(args.full)
args.pretrain = bool(args.pretrain)
args.download = bool(args.download)
args.token = bool(args.token)

if args.test_size > 5999 or args.test_size < 1:
    raise argparse.ArgumentError("Maximum test size of 5,999 videos | Minimum test size of 1 video")
    quit()

raw_path = str(os.path.abspath("./vatex/raw/") + "/")
tok_path = str(os.path.abspath("./vatex/tok") + "/")

jsons = ["vatex_training_v1.0", "vatex_validation_v1.0"]
fout = ["train", "val", "test"]
langs = ["en", "zh"]


class Preprocessor ():
    def __init__(self, formatted={}, ids={}):
        self.formatted = formatted
        self.ids = {}
        self.FULL = args.full
        self.TEST = args.test_size

    #creates common caption data structure
    def branch(self):
        return {langs[0]:[], langs[1]:[]}
    
    #opens the json files provided by VaTeX
    def open_vatex_json(self, data_file):
        with open(raw_path + data_file + ".json", "r", encoding="utf-8") as j:
            return json.load(j)
    
    def read_json(self):
        print("Reading:")
        for num, data_file in enumerate(jsons):
            data = self.open_vatex_json(data_file)
            
            data_type = fout[jsons.index(data_file)]
            self.ids[data_type] = []
            caps_dict = {} 
            
            print("--", data_file + ".json")
            for raw_dict in data:                
                #format video start and stop time as video ID
                vid = self.format_id(raw_dict)
                
                #save video ID as key for captions
                caps_dict[vid] = self.branch()
                self.ids[data_type].append(vid)
                
                if "enCap" in raw_dict.keys():
                    #if using the full dataset, don't truncate data
                    if self.FULL is True:
                        caps_dict[vid][langs[0]] += raw_dict["enCap"]
                    #otherwise, truncate dataset to parallel captions only
                    else:
                        caps_dict[vid][langs[0]] += raw_dict["enCap"][-5:]
                if "chCap" in raw_dict.keys():
                    #if using the full dataset, don't truncate data
                    if self.FULL is True:
                        caps_dict[vid][langs[1]] += raw_dict["chCap"]
                    #otherwise, truncate dataset to parallel captions only
                    else:
                        caps_dict[vid][langs[1]] += raw_dict["chCap"][-5:]
            self.formatted[data_type] = caps_dict 
    
    #returns a video ID in the format "id=clip_start=clip_duration"
    def format_id(self, raw_dict):
        vid = [""]
        vid[0] = raw_dict["videoID"][0:11]
        vid += raw_dict["videoID"][12:].split("_")
        
        #get number of seconds from timestamp
        vid[1] = datetime.timedelta(seconds = int(vid[1]))
        vid[2] = datetime.timedelta(seconds = int(vid[2]))

        #calculate clip duration
        vid[2] = (str(vid[2] - vid[1]))
        vid[1] = str(vid[1])
        vid = "=".join(vid)
        return vid

    #trim formatted[][] container
    def clean_set(self, fset, ids_trim):
        num = 0
        fmt = {}
        for i in self.formatted[fout[fset]]:
            if num >= ids_trim: 
                fmt[i] = self.formatted[fout[fset]][i]
            num += 1
        self.formatted[fout[fset]] = fmt

    #create test set from val and train set
    def build_new_test(self):
        print("Building Test Set:")
        ids_trim = int(self.TEST / 2)
        
        self.formatted["test"] = {}
        self.ids["test"] = []
        
        #move captions from train and val sets to test set (for new BPE)
        for fset in range (0, 2):
            print("--", fout[fset])
            for num, i in enumerate(self.formatted[fout[fset]]):
                if num < ids_trim:
                    self.formatted[fout[2]][i] = self.formatted[fout[fset]][i]
            self.clean_set(fset, ids_trim)
            
            #move n/2 video IDs from train ids to test ids
            self.ids[fout[2]] += self.ids[fout[fset]][:ids_trim]
            self.ids[fout[fset]] = self.ids[fout[fset]][ids_trim:]
    
    #move captions from val set only to test set (for pre-extracted BPE)
    def build_val_test(self):
        print("Bulding Test Set:")
        print("--", fout[1])
        
        ids_trim = 1000
        self.formatted["test"] = {}
        self.ids["test"] = []
        
        #move captions from val set to test set (for pre-encoded BPE)
        for num, i in enumerate(self.formatted[fout[1]]):
            if num < ids_trim:
                self.formatted[fout[2]][i] = self.formatted[fout[1]][i]
        self.clean_set(1, ids_trim)
        
        #move n/2 video IDs from train ids to test ids
        self.ids[fout[2]] += self.ids[fout[1]][:ids_trim]
        self.ids[fout[1]] = self.ids[fout[1]][ids_trim:]
    
    #output video ids and clip durations to files
    def export(self):
        print("Writing:")
        for file in fout:
            #output captions to json for later use 
            with open(raw_path + file + ".cap.json", "w", encoding="utf-8") as f:
                print("--", file + ".cap.json")
                self.out = self.formatted[file]
                json.dump(self.out, f)
                
            with open(raw_path + file + ".ids", "w", encoding="utf-8") as l:
                print("--", file + ".ids")
                for line in self.ids[file]:
                    l.write(line + "\n")
    
    def parse_new(self):
        #read json into formatted[][] container
        self.read_json()
        #build the test set from the train and val sets
        self.build_new_test()
        #output data to files
        self.export()
        
    def parse_pretrained(self):
        #read_jsons into formatted[][] container
        self.read_json()
        #build test set from the validation set
        self.build_val_test()
        #output formatted[][] data to files
        self.export()
        

class Tokenizer ():
    def __init__(self, formatted={}, preprocessed={}):
        self.formatted = formatted
        self.preprocessed = preprocessed
        
    #creates common caption data structure
    def branch(self):
        return {langs[0]:[], langs[1]:[]}
        
    #opens the json files created by the "Processor" class
    def open_cap_json(self, file):
        with open(raw_path + file + ".cap.json", encoding="utf-8") as j:
            return json.load(j)
        
    #for each video in the downloaded dataset, tokenize and prepare the associated captions.
    def format_from_dirs(self):
        print("Caching Directories:")
        dirs = {}
        #for each listing in the 'raw' directory, add to dirs if each item is a subdirectory
        for item in os.listdir(raw_path):
            if os.path.isdir(os.path.join(raw_path, item)):
                if ".vids" not in item:
                    continue
                print("--", item)
                item = item.split(".")[0]
                dirs[item] = []
                
        print("Collecting Captions:")
        #for each video in each set (train/val/test), get each video name (e.g. "test.ids.21f_nGAJC.mp4")
        for vdir in dirs.keys():
            print("--", vdir)
            v_path = os.path.join(raw_path, str(vdir + ".ids.vids"))
            for video in os.listdir(v_path):
                dirs[vdir].append(video)
        
        #for each preprocessed caption file, add captions to "formatted[][]" container
        for file in fout:
            self.formatted[file] = self.branch()
            data = self.open_cap_json(file)
            
            #add captions to "formatted[][]" container
            for fileID in dirs[file]:
                for videoID in data.keys():
                    if fileID.split(".")[2] == videoID.split("=")[0]:
                        self.formatted[file][langs[0]] += data[videoID][langs[0]]
                        self.formatted[file][langs[1]] += data[videoID][langs[1]]

    #if preprocessing and tokenizing are conjoined,
    def format_from_preprocessed(self):
        self.formatted = {}
        for file in fout: 
            #{langs[0]:[], langs[1]:[]}
            self.formatted[file] = self.branch()
            
            for caps_dict in self.preprocessed[file]:
                self.formatted[file][langs[0]] += self.preprocessed[file][caps_dict][langs[0]]
                self.formatted[file][langs[1]] += self.preprocessed[file][caps_dict][langs[1]]
    
    #from "train.cap.json" VaTeX jsons, re-construct formatted[][] container
    def format_from_json(self):
        for file in fout:
            self.formatted[file] = self.branch()
            data = self.open_cap_json(file)
            
            #for each video ID in the caption jsons, add to "formatted[][]" container
            for videoID in data:
                self.formatted[file][langs[0]] += data[videoID][langs[0]]
                self.formatted[file][langs[1]] += data[videoID][langs[1]]
        
    #tokenize and output captions from the "formatted[][]" container to ".tok" files
    def tokenize(self):
        #initialize tokenizers
        mt = MosesTokenizer(lang="en")
        jieba.initialize()
        jieba.setLogLevel(20)
        
        if self.formatted == {}:
            raise ValueError("Formatted container required: use format_from_... or give through class arguments")
            quit()
        
        print("Tokenizing:")
        #for each file and language in the formatted[][] container, tokenize by language and save to file
        for file in fout:
            for lang in langs:
                with open(tok_path + file + ".tok." + lang, "w", encoding="utf-8") as f:
                    print("--", file + ".tok." + lang)
                    if lang == langs[0]:
                        for line in self.formatted[file][lang]:
                            words = mt.tokenize(line, return_str=True, escape=False) #tokenize English with moses
                            f.write(words + "\n")
                    
                    elif lang == langs[1]:
                        for line in self.formatted[file][lang]:
                            words = jieba.lcut(line, cut_all=True) #tokenize Chinese with jieba
                            words = " ".join(words)
                            f.write(words + "\n")


if __name__ == "__main__":
    preprocessor = Preprocessor()

    if args.download is True: #preprocess without tokenizing
        preprocessor.parse_new()
        quit()
    elif args.token is True: #tokenize without preprocessing
        tokenizer = Tokenizer()
        tokenizer.format_from_json()
    elif args.pretrain is True: #preprocess with pre-extracted BPE and tokenize
        preprocessor.parse_pretrained()  
        tokenizer = Tokenizer(preprocessed=preprocessor.formatted)
        tokenizer.format_from_preprocessed()
        form = tokenizer.data
    else: #default is to preprocess and tokenize from "*.cap.json" files
        preprocessor.parse_new()
        tokenizer = Tokenizer(preprocessed=preprocessor.formatted)    
        tokenizer.format_from_json()
    tokenizer.tokenize()