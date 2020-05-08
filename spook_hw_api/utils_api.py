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

from random import randint

## BINARY OPERATION ###################################
# To binary representation -
# Takes a value 'val', and returns its
# bits representation of size 'size'
def to_bin(val, size, little_endian=True):
    val_bin = size*[0];
    val_tmp = val
    index=0
    while index<size:
        val_bin[index] = val_tmp & 0b1
        val_tmp = (val_tmp >> 1)
        index=index+1

    # Correct endianess if neede
    if not(little_endian):
        val_bin.reverse()

    return val_bin

# Return the integer represented by the bits given
def from_bin(bits, size=None, little_endian=True):
    # Check for the length  
    lb = size
    if size==None:
        lb=len(bits)

    res_int = 0
    for ifb,b in enumerate(bits):
        if b:
            if little_endian:
                res_int = res_int + (2**ifb)
            else:
                res_int = res_int + (2**(lb-1-ifb))

    # Return value
    return res_int

# To binary representation
# for a list
def list_to_bin(lval, size_b, sizel=None, little_endian=True):
    # Check for the length
    lv = sizel
    if sizel==None:
        lv=len(lval)

    # Create the list
    lval_bin = []
    for lval_e in lval:
        if little_endian:
            lval_bin = lval_bin + to_bin(lval_e,size_b,little_endian=True)
        else:
            lval_bin = to_bin(lval_e,size_b,little_endian=False) + lval_bin

    # Return 
    return lval_bin

# From binary representation
# for a list
def list_from_bin(lbin, size_b, sizelb=None, little_endian=True):
    # Check for size
    llbin=sizelb
    if sizelb==None:
        llbin = len(lbin)

    # Regenerate list from bin
    elem_amount = int(llbin/size_b)
    lval = elem_amount*[0]

    for ebin in range(elem_amount):
        if little_endian:
            lval[ebin] = from_bin(lbin[size_b*ebin : size_b*ebin + size_b],size_b,little_endian=True)
        else:
            lval[ebin] = from_bin(lbin[size_b*ebin : size_b*ebin + size_b],size_b,little_endian=False)
   
    #Return
    return lval


# Extract bits - 
# Takes a value 'val', and return 
# the value equals to the first 'size' bits
def ext_bits(val, size):
    mask = 2**size-1
    masked_val = val & mask
    return masked_val


## RANDOM operation ####################################
def rand_bytes_vec(size):
    return [randint(0,255) for b in range(size)]

