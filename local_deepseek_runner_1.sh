#!/bin/bash

set -e

#export HF_TOKEN='*************'
export HF_HUB_CACHE='/data/hf_home/hub/'
export RUNNER_NAME="mi355x-amd"

export HF_HUB_CACHE_MOUNT='/data/'
export GITHUB_WORKSPACE="$HOME/dev/InferenceMAX_jtoivone"

for tp in 8; do 
  for isl_osl in "1024,1024,dsr1" "8192,1024,dsr1" "1024,8192,dsr1"; do
  #for isl_osl in "3500,1500,dsr1"; do
  #for isl_osl in "1024,1024,dsr1" "8192,1024,dsr1"; do
  #for isl_osl in "128,16,dsr1"; do # testing
    isl=$( echo ${isl_osl} | cut -f 1 -d ',')
    osl=$( echo ${isl_osl} | cut -f 2 -d ',')
    exp_name=$( echo ${isl_osl} | cut -f 3 -d ',')

    echo "isl $isl osl $osl exp_name $exp_name"

    random_range_ratio=0.8
    max_model_len=$(( isl + osl ))
    

    #export IMAGE='rocm/7.0:rocm7.0_ubuntu_22.04_vllm_0.10.1_instinct_20250927_rc1'
    #export IMAGESHORTNAME='rocm7.0_ubuntu_22.04_vllm_0.10.1_instinct_20250927_rc1-nonlinear'

    #export IMAGE='rocm/vllm-private:355_wip_230_7ed998453_1003'
    #export IMAGESHORTNAME='vllm-private_355_wip_230_7ed998453_1003'

    #export IMAGE=rocm/7.0:rocm7.0_ubuntu_22.04_vllm_0.10.1_instinct_20250915
    #export IMAGESHORTNAME=rocm7.0_ubuntu_22.04_vllm_0.10.1_instinct_20250915

    #export IMAGE=rocm/vllm-private:355_wip_311_eccac3268_1023
    #export IMAGESHORTNAME=vllm-private-355_wip_311_eccac3268_1023

    #export IMAGE=rocm/vllm-private:355_wip_322_3d192ffe9_1026
    #export IMAGESHORTNAME=vllm-private-355_wip_322_3d192ffe9_1026

    #export IMAGE=lmsysorg/sglang:v0.5.4.post3-rocm700-mi35x
    #export IMAGESHORTNAME=sglang_v0.5.4.post3-rocm700-mi35x

    export IMAGE=lmsysorg/sglang:v0.5.4-rocm700-mi35x
    export IMAGESHORTNAME=sglang_v0.5.4-rocm700-mi35x

    export MODEL='deepseek-ai/DeepSeek-R1-0528'
    export FRAMEWORK='sglang_dsr1'
    export PRECISION='fp8'
    export ISL=${isl}
    export OSL=${osl}
    export MAX_MODEL_LEN=${max_model_len}
    export RANDOM_RANGE_RATIO=${random_range_ratio}
    export TP_LIST='[4,8]'
    export TP=$tp
    export CONC_LIST='[4, 8, 16, 32, 64]' 
    export PORT=8008

    export EXP_NAME="${exp_name}"
    export EXP_NAME_LONG="${exp_name}_${ISL:0:1}k${OSL:0:1}k"

    mkdir -p results/${IMAGESHORTNAME}/${EXP_NAME}

    for CONC in 4 8 16 32 64; do
        export RESULT_FILENAME=${EXP_NAME_LONG}_${PRECISION}_${FRAMEWORK}_tp${TP}_conc${CONC}_${RUNNER_NAME}
        export CONC

        if [ ! -f "results/${IMAGESHORTNAME}/${EXP_NAME}/$RESULT_FILENAME.json" ]; then
          echo "Running experiment to produce results/${EXP_NAME}/${IMAGESHORTNAME}/$RESULT_FILENAME.json"
          bash ./runners/launch_${RUNNER_NAME}.sh
          mv $RESULT_FILENAME.json results/${IMAGESHORTNAME}/${EXP_NAME}/
          #mv $RESULT_FILENAME.acc_check results/${IMAGESHORTNAME}/${EXP_NAME}/
        else
          echo "Result file results/${IMAGESHORTNAME}/${EXP_NAME}/$RESULT_FILENAME.json exists already, moving on!"
        fi
    done
  done
done
