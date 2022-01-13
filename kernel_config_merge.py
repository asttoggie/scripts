#!/usr/bin/env python3
# Comapring two kernel configuration and merge it into one file

import re
import sys, os

if "help" in sys.argv[1]:
    print("""
first arg = base configuration
second arg = configuration which should merge
third arg = filename after merge
help = to see this text""")
    sys.exit()

if len(sys.argv) < 4:
    print("Please provide files as argunent")
    sys.exit()

for i in range(1, 3):
    f = sys.argv[i]
    if not os.path.isfile(f):
        print("File {} not found".format(f))
        sys.exit()
        
def pars_line(line):
    line = line.rstrip()
    if line.startswith("#") and "is not set" not in line:
        return False
    elif "is not set" in line:
        return([line.split()[1], "n"])
    elif line.endswith(("=y", "=m")):
        return(line.split("="))
    else:
        return False

def read_file(file_name):
    lines = {}
    try:
        with open(file_name, 'r', encoding='utf-8') as f:
            for line in f:
                if pars_line(line):
                    lines[pars_line(line)[0]] = pars_line(line)[1]
        if lines:
            return lines
        else:
            print("Cannot parse file: {}".format(file_name))
            sys.exit()
    except UnicodeDecodeError:
        print("Non-text file {}".format(file_name))
        sys.exit()

result = read_file(sys.argv[1])
result.update(read_file(sys.argv[2]))

with open(sys.argv[3], 'w', encoding='utf-8') as f:
    for key, value in result.items():
        if value == "n":
            f.write("# {} is not set\n".format(key))
        if value == "y" or value == "m":
            f.write("{}={}\n".format(key, value))
