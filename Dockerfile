ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG WHISPER_CPP_VERSION

ARG WHISPER_CPP_VERSION
ENV SYCL_CACHE_PERSISTENT=1
ENV SYCL_CACHE_DIR=/models/sycl_cache
ENV SYCL_DEVICE_ALLOWLIST=BackendName:level_zero

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN mkdir -p /whisper

WORKDIR /whisper

RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        netcat-traditional \
        python3-pip \
        python3-venv

RUN \
    git clone https://github.com/ser/wyoming-whisper-api-client.git wyoming-whisper-api-client \
    && cd wyoming-whisper-api-client \
    && script/setup

RUN \
    git clone https://github.com/ggerganov/whisper.cpp.git whisper.cpp \
    && cd whisper.cpp \
    && git reset --hard v${WHISPER_CPP_VERSION} \
    && cmake -B build -DGGML_SYCL=ON -DCMAKE_C_COMPILER=icx -DCMAKE_CXX_COMPILER=icpx -DGGML_SYCL_F16=ON \
    && cmake --build build -j --config Release

COPY run.sh /whisper

RUN chmod +x ./run.sh

CMD ./run.sh

HEALTHCHECK --start-period=10m \
    CMD echo '{ "type": "describe" }' \
        | nc -w 1 localhost 7891 \
        | grep -iq "whisper-cpp" \
        || exit 1
