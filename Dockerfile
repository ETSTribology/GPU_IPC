FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    cmake \
    build-essential \
    libeigen3-dev \
    libglew-dev \
    freeglut3-dev \
    libx11-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone --recursive <REPO_URL> .

RUN mkdir -p build && cd build \
    && cmake .. -DCMAKE_BUILD_TYPE=Release \
    && make -j$(nproc)

WORKDIR /app/build

CMD ["./gipc"]
