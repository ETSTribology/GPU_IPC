FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

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
    ccache && \
    rm -rf /var/lib/apt/lists/*

ENV CCACHE_DIR=/ccache
ENV CC="ccache gcc" CXX="ccache g++"
RUN ccache -M 5G

ENV CUDA_HOME=/usr/local/cuda
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${CUDA_HOME}/extras/CUPTI/lib64:${LD_LIBRARY_PATH}
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LIBRARY_PATH=${CUDA_HOME}/lib64:${LIBRARY_PATH}

WORKDIR /app

ARG REPO_URL=https://github.com/ETSTribology/GPU_IPC.git
RUN git clone --recursive ${REPO_URL} .

RUN mkdir -p build && \
    cd build && \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CUDA_COMPILER_LAUNCHER=ccache \
        -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME} \
        -DCMAKE_CUDA_COMPILER=${CUDA_HOME}/bin/nvcc && \
    cmake --build . -- -j$(nproc)

WORKDIR /app/build
ENV DISPLAY=:0
ENTRYPOINT ["./gipc"]
