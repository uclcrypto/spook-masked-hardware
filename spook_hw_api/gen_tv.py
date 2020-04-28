#!/usr/bin/env python3

import sys

from spook_hw_api import utils_spook_tb

args = sys.argv
largs = len(args)

outdir='./'
if largs>1:
    outdir= str(args[1])

nist_like_tv_f = 'LWC_AEAD_KAT_128_128.txt'
if largs>2:
    nist_like_tv_f = str(args[2])

suffix_tv = 'default'
if largs>3:
    suffix_tv = str(args[3])

mode = 'glob'
if largs>4:
    mode = str(args[4])

dshare = 2
if largs>5:
    dshare = int(args[5])


utils_spook_tb.build_hw_tv_files(outdir=outdir,fname=nist_like_tv_f,suffix=suffix_tv,mode=mode,DSHARE=dshare,L_ENDIAN=False)
