#!/usr/bin/python3
import os, re


pwd_files = []

for d, dirs, files in os.walk('data'):
    pwd_files = files
    break

GO = 1

if GO != 1:
    print('stop')
else:
    for file in pwd_files:
        f = open(d + '/' + file, 'rb')
        for line in f.readlines():
            try:
                decode_line = line.decode()
                flags = re.findall("[A-Z0-9]{31}=", decode_line)
                if flags:
                    for flag in flags:
                        print(flag, flush=True)
            except:
                continue
        f.close()
