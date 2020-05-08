#!/usr/bin/env python3

# MIT License
# 
# Copyright (c) 2020 UCLouvain
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


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
