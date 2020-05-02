#!/usr/bin/python3
import os, re, time


pwd_files = []

for d, dirs, files in os.walk('data'):
    pwd_files = files
    break

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

current_time = time.time()
pcaps = os.listdir('data/')

for pcap in pcaps:
    if pcap == 'record.sh' or pcap == 'config':
        continue
    if (current_time - os.path.getctime('data/' + pcap))//60 > 5:
        try:
            os.remove('data/'+pcap)
            print(pcap + ' was deleted. He is older then 5 minutes.')
        except IsADirectoryError:
            continue