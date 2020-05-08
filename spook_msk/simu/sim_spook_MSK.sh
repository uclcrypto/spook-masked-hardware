#!/bin/bash

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


####### Tools paths
# Iverilog paths
IV=iverilog
VVP=vvp

####### Design directories paths
export PYTHONPATH=../../:$PYTHONPATH
export SHAD_DIR=../hdl/shadow_512_hdl
export CLYDE_DIR=../hdl/clyde_MSK_SB3c
export MODE_DIR=../hdl/mode_hdl

####### Main spook module
export MAIN_MODULE=spook_MSK

####### Testbench directory and module
TB_DIR=../tb
TB_MODULE=tb_spook_MSK

# VCD file (if dumping selected, see after)
SIM_FILE_PREF=sim

# Testvector directory path
TV_DIR=../../spook_hw_api

# TVs file (NIST LWC like)
TV_REF_FILE_PATH=$TV_DIR/LWC_AEAD_KAT_128_128_reduced.txt

# Prefix used in the prefix file
TV_FILE_PREFIX=sim_behav

# Testvector mode:
#     enc: encryption only
#     dec: decryption only
#     glob: encryption and decryption
TV_MODE=glob

####### Custom config
# Set to 1 if you want to generate a dumping file
DUMP_FILE=0

# Set to 1 if you want to use a temporary workspace
CREATE_TMP_DIR=1

# Generation parameter the spook core (cfr doc for more information)
DSHARE=2
PDSBOX=2
PDLBOX=1

# Set to 1 if you want to *all* signals in the testbench.
DUMP_ALL=1

###########################################

# Null path
NULL=/dev/null

# Temporary directory
if [ $CREATE_TMP_DIR -eq 1 ]
then
    export OUT_DIR=`mktemp -d -t sim_spook_UMSK-XXXXXXXXXXXXXXXX`                                                                                                                
else
    export OUT_DIR=workspace_sim_MSK
fi
echo "Files are written in $OUT_DIR"

rm -f simdir
ln -s $OUT_DIR simdir

# Check if the tmp dir should be created
ls $OUT_DIR &> $NULL || mkdir $OUT_DIR

# Generate the Testvector 
$TV_DIR/gen_tv.py $OUT_DIR $TV_REF_FILE_PATH $TV_FILE_PREFIX $TV_MODE $DSHARE

# TV FILE FORMAT
TV_F_FORMAT=tv_${TV_FILE_PREFIX}_${TV_MODE}

# Used path
VCD_PATH=$SIM_FILE_PREF.vcd
SIM_PATH=$OUT_DIR/$SIM_FILE_PREF.out
TB_PATH=$TB_DIR/$TB_MODULE.v
TV_PATH_IN=$TV_F_FORMAT.txt
TV_PATH_OUT=${TV_F_FORMAT}_HW_res.txt

# Move tv to OUT DIR
#cp $TV_F_FORMAT.txt $OUT_DIR

echo Simulate.
# Build simulation file
$IV -y $MODE_DIR -y $CLYDE_DIR -y $SHAD_DIR -I $MODE_DIR -I $CLYDE_DIR -s $TB_MODULE \
    -D VCD_PATH=\"$VCD_PATH\" \
    -D TV_PATH_IN=\"$TV_PATH_IN\" \
    -D TV_PATH_OUT=\"$TV_PATH_OUT\" \
    -D DUMP_FILE=$DUMP_FILE \
    -D DSHARE=$DSHARE \
    -D PDSBOX=$PDSBOX \
    -D PDLBOX=$PDLBOX \
    -D behavioral=1 \
    -D DUMP_ALL=$DUMP_ALL \
    -o $SIM_PATH $TB_PATH

# Run simulation
(cd $OUT_DIR && time $VVP $SIM_FILE_PREF.out)

# cmp results 
cmp $OUT_DIR/${TV_PATH_OUT} $OUT_DIR/${TV_F_FORMAT}_res.txt && echo "SIMULATION SUCCEEDED" || echo "SIMULATION FAILED"


