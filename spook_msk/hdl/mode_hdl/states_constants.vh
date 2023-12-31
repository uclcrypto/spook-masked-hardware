/*
    Copyright 2020 UCLouvain

    Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        https://solderpad.org/licenses/SHL-2.0/

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
`ifndef _FSM_STATES_SH
`define _FSM_STATES_SH

// FSM states ////////////////
localparam WAIT_INST = 5'd1,
//
WAIT_KEY = 5'd2,
LOAD_KEY = 5'd3,
//
WAIT_NONCE = 5'd4,
LOAD_NONCE = 5'd5,
//
START_CMP_B = 5'd6,
WAIT_CMP_B = 5'd7,
//
START_FIRST = 5'd8,
WAIT_FIRST = 5'd9,
//
WAIT_D = 5'd10,
LOAD_D = 5'd11,
WAIT_OUT_D = 5'd12,
UPDATE_DIG_MODE = 5'd13,
WAIT_OUT_HEAD_D = 5'd14,
WAIT_OUT_HEAD_D_EMPTY = 5'd15,
REDIRECT_M_DIG = 5'd16,
//
START_DIG_D = 5'd17,
WAIT_DIG_D = 5'd18,
//
PREPARE_TAG_CMP = 5'd19,
WAIT_TAG_CMP = 5'd20,
WAIT_OUT_HEAD_TAG = 5'd21,
WAIT_OUT_TAG = 5'd22,
WAIT_TAG = 5'd23,
LOAD_TAG = 5'd24,
RESULT_TAG = 5'd25,
//
WAIT_OUT_SUCCESS = 5'd26,
WAIT_OUT_FAILURE = 5'd27,
// 
WAIT_REFRESH_INIT = 5'd28,
WAIT_REFRESH_END = 5'd29,
// 
WAIT_SEED = 5'd30,
LOAD_SEED = 5'd31;
`endif
