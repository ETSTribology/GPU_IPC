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
    x11-apps && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

ARG REPO_URL=https://github.com/ETSTribology/GPU_IPC.git
RUN git clone --recursive ${REPO_URL} .

RUN mkdir -p build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    cmake --build . -- -j$(nproc)

WORKDIR /app/build

ENV DISPLAY=:0

ENTRYPOINT ["./gipc"]
