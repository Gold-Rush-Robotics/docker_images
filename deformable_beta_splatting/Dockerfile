FROM nvcr.io/nvidia/cuda:12.5.1-cudnn-devel-ubuntu22.04
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
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
RUN git clone --single-branch --branch main https://github.com/RongLiu-Leo/beta-splatting.git
WORKDIR /beta-splatting
RUN pip3 install torch torchvision 
COPY versioning.bash /beta-splatting/versioning.bash
RUN chmod +x /beta-splatting/versioning.bash
RUN touch requirements.txt
RUN pip install --no-build-isolation git+https://github.com/rmbrualla/pycolmap@cc7ea4b7301720ac29287dbe450952511b32125e
RUN pip install --no-build-isolation git+https://github.com/RongLiu-Leo/nerfview@9c96374139351e5a1d8dc2f95937cff97049c17b
RUN pip install --no-build-isolation git+https://github.com/rahul-goel/fused-ssim@8bdb59feb7b9a41b1fab625907cb21f5417deaac
RUN pip install --no-build-isolation git+https://github.com/fraunhoferhhi/PLAS@4f1109c94f29a5a6de62bdf8f20cb3ce1ff0e680
RUN ./versioning.bash


# Then install everything else
# RUN pip install --no-cache-dir -r requirements.txt
# RUN pip install --no-build-isolation --no-cache-dir -r requirements.txt
RUN pip install -e .

ENV PATH="/usr/local/cuda-12.5/bin:$PATH"   
ENV LD_LIBRARY_PATH="/usr/local/cuda-12.5/lib64:$LD_LIBRARY_PATH"

WORKDIR /
RUN git clone --recursive https://github.com/nvlabs/instant-ngp.git
WORKDIR /instant-ngp
RUN apt-get install build-essential git python3-dev python3-pip libopenexr-dev libxi-dev \
libglfw3-dev libglew-dev libomp-dev libxinerama-dev libxcursor-dev -y
RUN cmake . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
RUN cmake --build build --config RelWithDebInfo -j