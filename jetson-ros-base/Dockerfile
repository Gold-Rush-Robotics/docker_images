ARG L4T_VERSION=l4t-r36.4.0
ARG IMAGE_NAME=nvcr.io/nvidia/l4t-jetpack:r36.4.0


FROM ${IMAGE_NAME}

# ROS2 distribution
ARG ROS2_DIST=humble


ENV DEBIAN_FRONTEND=noninteractive

ENV ROS_DISTRO=humble

# Add the ROS 2 apt repository (Ubuntu 22.04 Jammy, arm64) so ros-humble-*
# packages are available.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg2 \
        lsb-release \
        locales \
        software-properties-common \
        python3-pip \
        python3-full \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && add-apt-repository universe -y \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
        > /etc/apt/sources.list.d/ros2.list \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# install ros2 packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-ros-core \
    && rm -rf /var/lib/apt/lists/*


RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    git \
    python3-colcon-common-extensions \
    python3-colcon-mixin \
    python3-rosdep \
    python3-vcstool \
    curl \
    && rm -rf /var/lib/apt/lists/*

# bootstrap rosdep
RUN rosdep init && \
  rosdep update --rosdistro $ROS_DISTRO

# setup colcon mixin and metadata
RUN colcon mixin add default \
      https://raw.githubusercontent.com/colcon/colcon-mixin-repository/master/index.yaml && \
    colcon mixin update && \
    colcon metadata add default \
      https://raw.githubusercontent.com/colcon/colcon-metadata-repository/master/index.yaml && \
    colcon metadata update

# install ros2 packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-ros-base=0.10.0-1* \
    && rm -rf /var/lib/apt/lists/*

# Install the ZED ROS2 Wrapper
ENV ROS_DISTRO=${ROS2_DIST}

# Copy the sources in the Docker image
WORKDIR /root/ros2_ws/src

RUN /usr/bin/python3 -m pip install --no-cache-dir \
        opencv-python-headless && \
    /usr/bin/python3 -m pip install --no-cache-dir --ignore-installed sympy && \
    /usr/bin/python3 -m pip install --no-cache-dir \
        --index-url https://pypi.jetson-ai-lab.io/jp6/cu126 \
        torch torchvision && \
    /usr/bin/python3 -m pip install --no-cache-dir \
        ultralytics \
        transforms3d && \
    /usr/bin/python3 -m pip install --no-cache-dir --force-reinstall \
        "numpy==1.26.4"

# ---------------------------------------------------------------------------
# Runtime libs required by the Jetson PyTorch wheel:
#   - libopenblas0: dynamic BLAS
#   - libcudss0-cuda-12: NVIDIA cuDSS (not shipped with JetPack by default).
#     Installs under /usr/lib/aarch64-linux-gnu/libcudss/12/ so add an
#     ld.so.conf entry.
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        libopenblas0 \
        libopenblas-dev \
        libcap-dev \
        libompl-dev \
        python3-pyqt5 \
    && curl -sSL -o /tmp/cuda-keyring.deb \
        https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/arm64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i /tmp/cuda-keyring.deb && \
    rm -f /tmp/cuda-keyring.deb && \
    apt-get update && apt-get install -y --no-install-recommends \
        libcudss0-cuda-12 \
    && rm -rf /var/lib/apt/lists/* && \
    echo "/usr/lib/aarch64-linux-gnu/libcudss/12" > /etc/ld.so.conf.d/cudss.conf && \
    ldconfig

WORKDIR /opt
RUN git clone \
		--branch isaac_sim_junk \
		--single-branch \
		--recurse-submodules \
		https://github.com/Gold-Rush-Robotics/IGVC_robot_2026.git && \
	git -C /opt/IGVC_robot_2026 submodule update --init --recursive

WORKDIR /opt/IGVC_robot_2026
RUN apt-get update && \
	if [ -d src ]; then \
		rosdep install --from-paths src --ignore-src -r -y --rosdistro humble; \
	else \
		rosdep install --from-paths . --ignore-src -r -y --rosdistro humble; \
	fi && \
	rm -rf /var/lib/apt/lists/*



WORKDIR /root/ros2_ws

# Setup environment variables 
COPY ros_entrypoint_jetson.sh /sbin/ros_entrypoint.sh
RUN sudo chmod 755 /sbin/ros_entrypoint.sh

ENTRYPOINT ["/sbin/ros_entrypoint.sh"]
CMD ["bash"]
