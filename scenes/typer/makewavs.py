import json
import os

words = {}
with open("words.json") as f:
    txt = f.read()
    words = json.loads(txt)

for word in words["long"]:
    os.popen("./sam -wav ./samwords/" + word + ".wav " + word)

for word in words["ours"]:
    if word == "abcdefghijklmnopqrstuvwxyandz": continue
    os.popen("./sam -wav ./samwords/" + word + ".wav " + word)

# i made abcdefghijklmnopqrstuvwxyandz by telling sam to say:
# "ay b c d e f g h i j k l m n o p q r s t u v w"
# at which point he stopped, so i made him say another prompt:
# "ex y and z"
# and combined the two & spread them out with the gap between j and k
# thanks
