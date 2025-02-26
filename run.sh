#!/bin/bash

set -o pipefail

echo "Language set to: $LANG"
echo "Extra arguments set to: $EXTRA_ARGS"
echo "Initial prompt set to: $PROMPT"

if [ -z "$BEAM_SIZE" ]; then
    BEAM_SIZE=5
fi
echo "Beam size set to $BEAM_SIZE"

if [ -z "$MODEL" ]; then
    echo "Model name not set" >&2
    exit 1
fi
MODEL_FILE="/models/ggml-$MODEL.bin"

if [ ! -f "/models/download-ggml-model.sh" ]; then
    curl https://raw.githubusercontent.com/ggerganov/whisper.cpp/refs/heads/master/models/download-ggml-model.sh > /models/download-ggml-model.sh && chmod +x /models/download-ggml-model.sh
fi

if [ ! -f "$MODEL_FILE" ]; then
    cd /models || { echo "Could not open /models"; exit 1; }
    if ! ./download-ggml-model.sh ${MODEL}; then
        echo "Failed to download $MODEL model" >&2
        exit 1
    fi
fi

( cd /whisper/whisper.cpp && build/bin/whisper-server -l ${LANG} -bs ${BEAM_SIZE} -m ${MODEL_FILE} --host 127.0.0.1 --port 8910 --suppress-nst --prompt "$PROMPT" ${EXTRA_ARGS} ) &
( cd /whisper/wyoming-whisper-api-client && script/run --uri tcp://0.0.0.0:7891 --api http://127.0.0.1:8910/inference )
