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
ENV CC="ccache gcc" CXX="ccache g++" CUDA_NVCC_EXECUTABLE="ccache /usr/local/cuda/bin/nvcc"
RUN ccache -M 5G  # Set ccache max size to 5GB

WORKDIR /app

ARG REPO_URL=https://github.com/ETSTribology/GPU_IPC.git
RUN git clone --recursive ${REPO_URL} .

ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:${LD_LIBRARY_PATH}
ENV PATH=/usr/local/cuda/bin:${PATH}

RUN mkdir -p build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release \
             -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
             -DCMAKE_CUDA_COMPILER_LAUNCHER=ccache && \
    cmake --build . -- -j$(nproc)

WORKDIR /app/build

ENV DISPLAY=:0

ENTRYPOINT ["./gipc"]
