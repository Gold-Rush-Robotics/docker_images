FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git-lfs \
    git \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    zlib1g-dev \
    curl
WORKDIR /
RUN git clone https://github.com/newton-physics/newton.git
WORKDIR /newton
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
