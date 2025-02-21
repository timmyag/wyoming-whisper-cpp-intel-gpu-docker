#!/bin/bash

set -o pipefail

MODEL_FILE="/models/ggml-$MODEL.bin"

if [ ! -f "$MODEL_FILE" ]; then
    curl https://raw.githubusercontent.com/ggerganov/whisper.cpp/refs/heads/master/models/download-ggml-model.sh > /models/download-ggml-model.sh && chmod +x /models/download-ggml-model.sh
    cd /models && ./download-ggml-model.sh ${MODEL}
fi

( cd /data/whisper.cpp && build/bin/whisper-server -t 1 -bs 5 -m "$MODEL_FILE" --host 127.0.0.1 --port 8910 --suppress-nst ) &
( cd /data/wyoming-whisper-api-client && script/run --uri tcp://0.0.0.0:7891 --api http://127.0.0.1:8910/inference )