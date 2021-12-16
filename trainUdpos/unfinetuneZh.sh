#!/bin/bash
# Copyright 2020 Google and DeepMind.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

REPO=/content/cross-lingual/xtreme/
MODEL=${1:-bert-base-multilingual-cased}
DATA_DIR_=${3:-"$REPO/download/"}
OUT_DIR=${4:-"$REPO/outputs/"}

TASK='udpos'
LANGS='af,ar,bg,de,el,en,es,et,eu,fa,fi,fr,he,hi,hu,id,it,ja,kk,ko,mr,nl,pt,ru,ta,te,th,tl,tr,ur,vi,yo,zh,lt,pl,uk,ro'
NUM_EPOCHS=10
MAX_LENGTH=128
LR=2e-5

LC=""
if [ $MODEL == "bert-base-multilingual-cased" ] || [ $MODEL == "model_with_co" ] || [ $MODEL == "udpos.en-de_fr_hi_zh" ]; then
  MODEL_TYPE="bert"
elif [ $MODEL == "xlm-mlm-100-1280" ] || [ $MODEL == "xlm-mlm-tlm-xnli15-1024" ]; then
  MODEL_TYPE="xlm"
  LC=" --do_lower_case"
elif [ $MODEL == "xlm-roberta-large" ] || [ $MODEL == "xlm-roberta-base" ]; then
  MODEL_TYPE="xlmr"
fi

if [ $MODEL == "xlm-mlm-100-1280" ] || [ $MODEL == "xlm-roberta-large" ]; then
  BATCH_SIZE=2
  GRAD_ACC=16
else
  BATCH_SIZE=8
  GRAD_ACC=4
fi


DATA_DIR=$DATA_DIR_/$TASK/
OUTPUT_DIR="$OUT_DIR/$TASK/${MODEL}-LR${LR}-epoch${NUM_EPOCHS}-MaxLen${MAX_LENGTH}"
# mkdir -p $DATA_DIR
mkdir -p $OUTPUT_DIR

python $REPO/utils_preprocess.py \
--data_dir $DATA_DIR \
--output_dir $DATA_DIR --task udpos_tokenize \
--model_name_or_path $MODEL \
--model_type $MODEL_TYPE $LC \
--languages $LANGS \

# if [ $MODEL == "model_with_co" ]; then
#   MODEL=$MODEL/
# fi

# # cp $DATA_DIR_/$TASK/labels.txt $DATA_DIR
mkdir $OUTPUT_DIR/align.awesome.unfinetuned
for lang in zh; do
  mkdir $OUTPUT_DIR/align.awesome.unfinetuned/$lang
  python $REPO/third_party/run_tag.py \
    --data_dir $DATA_DIR \
    --model_type $MODEL_TYPE \
    --labels $DATA_DIR/labels.txt \
    --model_name_or_path $MODEL \
    --output_dir $OUTPUT_DIR/align.awesome.unfinetuned/$lang \
    --max_seq_length  $MAX_LENGTH \
    --num_train_epochs $NUM_EPOCHS \
    --gradient_accumulation_steps $GRAD_ACC \
    --per_gpu_train_batch_size $BATCH_SIZE \
    --save_steps 500 \
    --logging_steps 500 \
    --seed 1 \
    --learning_rate $LR \
    --do_train \
    --do_eval \
    --do_predict \
    --do_predict_dev \
    --evaluate_during_training \
    --predict_langs $LANGS \
    --log_file $OUTPUT_DIR/train.log \
    --eval_all_checkpoints \
    --overwrite_output_dir \
    --save_only_best_checkpoint $LC \
    --overwrite_cache \
    --aligned_suffix $lang.awesome.unfinetuned \

done


