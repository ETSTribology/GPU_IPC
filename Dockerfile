FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

ENV CUDA_HOME=/usr/local/cuda \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:${LD_LIBRARY_PATH} \
    PATH=/usr/local/cuda/bin:${PATH} \
    LIBRARY_PATH=/usr/local/cuda/lib64:${LIBRARY_PATH}

ENV CCACHE_DIR=/ccache \
    CC="ccache gcc" \
    CXX="ccache g++" \
    CUDA_NVCC_EXECUTABLE="ccache nvcc"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cmake \
        build-essential \
        libeigen3-dev \
        libglew-dev \
        freeglut3-dev \
        libx11-dev \
        git \
        x11-apps \
        ccache \
        ninja-build && \
    rm -rf /var/lib/apt/lists/* && \
    ccache -M 5G && \
    ccache -o compression=true && \
    ccache -o compression_level=9

WORKDIR /app

ARG REPO_URL=https://github.com/ETSTribology/GPU_IPC.git
ARG CUDA_ARCH=86
ARG BUILD_TYPE=Release
ARG NUM_JOBS=8

RUN git clone --recursive --depth 1 ${REPO_URL} .

RUN mkdir -p build

WORKDIR /app/build

RUN cmake .. \
    -GNinja \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CUDA_COMPILER_LAUNCHER=ccache \
    -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME} \
    -DCMAKE_CUDA_COMPILER=${CUDA_HOME}/bin/nvcc \
    -DCUDA_ARCHITECTURES=${CUDA_ARCH} \
    -DUSE_CCACHE=ON \
    -DCMAKE_CXX_FLAGS="-Wno-error" \        # Prevent warnings as errors for C++
    -DCMAKE_CUDA_FLAGS="-Wno-error"          # Prevent warnings as errors for CUDA

RUN ninja -j${NUM_JOBS} && \
    ccache -s && \
    rm -rf ${CCACHE_DIR}/*
    
ENV DISPLAY=:0

ENTRYPOINT ["./gipc"]
