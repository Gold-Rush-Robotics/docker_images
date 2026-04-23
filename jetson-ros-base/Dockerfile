ARG L4T_VERSION=l4t-r36.4.0
ARG IMAGE_NAME=nvcr.io/nvidia/l4t-jetpack:r36.4.0

FROM ${IMAGE_NAME}

ARG L4T_MAJOR=36
ARG L4T_MINOR=4

# ROS 2 distribution (built from source on Ubuntu 22.04 Jammy)
ARG ROS2_DIST=jazzy

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV ROS_DISTRO=${ROS2_DIST}
ENV ROS_PYTHON_VERSION=3
ENV TZ=Europe/Paris

RUN echo "$TZ" > /etc/timezone && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    apt-get update && \
    apt-get install -q -y --no-install-recommends tzdata locales && \
    locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=C.UTF-8 LANG=C.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Base tools
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -q -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        gnupg2 \
        lsb-release \
        software-properties-common \
        build-essential \
        cmake \
        git \
        sudo \
        less \
        udev \
        usbutils \
        jq \
        zstd \
        zip \
        unzip \
        pkg-config \
        libssl-dev \
        libusb-1.0-0-dev \
        zlib1g-dev \
        python3 \
        python3-dev \
        python3-pip \
        python3-wheel \
        python3-setuptools \
    && add-apt-repository universe -y \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# ROS 2 apt repo - used ONLY to pull rosdep/colcon tooling.
# The ROS packages themselves are built from source since there are no
# Jazzy binaries for Jammy.
# ---------------------------------------------------------------------------
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" \
        > /etc/apt/sources.list.d/ros2.list

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3-colcon-common-extensions \
        python3-colcon-mixin \
        python3-rosdep \
        python3-vcstool \
        python3-flake8 \
        python3-flake8-blind-except \
        python3-flake8-builtins \
        python3-flake8-class-newline \
        python3-flake8-comprehensions \
        python3-flake8-deprecated \
        python3-flake8-docstrings \
        python3-flake8-import-order \
        python3-flake8-quotes \
        python3-pytest \
        python3-pytest-cov \
        python3-pytest-repeat \
        python3-pytest-rerunfailures \
        python3-argcomplete \
    && rm -rf /var/lib/apt/lists/*

# Python build deps required by the ROS 2 source build
RUN python3 -m pip install --no-cache-dir -U \
        "setuptools==68.2.2" \
        "pip" \
        "empy==3.3.4" \
        "lark==1.1.9" \
        "catkin_pkg" \
        "numpy==1.26.4"

# ---------------------------------------------------------------------------
# System dependencies commonly needed by ROS 2 core packages
# (covers most rosdep keys; the rosdep pass below fills in the rest).
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        libacl1-dev \
        libasio-dev \
        libtinyxml2-dev \
        libcunit1-dev \
        libbullet-dev \
        libeigen3-dev \
        libyaml-cpp-dev \
        libssl-dev \
        libcurl4-openssl-dev \
        libzstd-dev \
        libpcl-dev \
        libboost-all-dev \
        qtbase5-dev \
        qtbase5-dev-tools \
        qtdeclarative5-dev \
        libqt5svg5-dev \
        libfreetype-dev \
        liblog4cxx-dev \
        liborocos-kdl-dev \
        libxaw7-dev \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        libx11-dev \
        libxext-dev \
        uncrustify \
        cppcheck \
        graphviz \
        libspdlog-dev \
        libfmt-dev \
        libbenchmark-dev \
        google-mock \
        libgmock-dev \
        libgtest-dev \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Bootstrap rosdep
# ---------------------------------------------------------------------------
RUN rosdep init && rosdep update --rosdistro ${ROS_DISTRO}

# ---------------------------------------------------------------------------
# Fetch Jazzy source and build it
# ---------------------------------------------------------------------------
ENV ROS_ROOT=/opt/ros/${ROS_DISTRO}
WORKDIR /tmp/ros2_src

RUN mkdir -p src && \
    curl -sSL https://raw.githubusercontent.com/ros2/ros2/${ROS_DISTRO}/ros2.repos \
        -o ros2.repos && \
    vcs import src < ros2.repos

# Install rosdep-provided system deps. Some keys are Noble-only; skip those.
RUN apt-get update && \
    rosdep install --from-paths src --ignore-src -y --rosdistro ${ROS_DISTRO} \
        --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers rmw_connextdds \
                     ignition-cmake2 ignition-math6 python3-catkin-pkg-modules \
                     python3-lark-parser python3-empy" \
    || true && \
    rm -rf /var/lib/apt/lists/*

# Build the core. Use --merge-install to land everything under one prefix.
# Limit parallelism via MAKEFLAGS at build time to avoid OOM on Jetson.
ARG COLCON_PARALLEL=4
RUN mkdir -p ${ROS_ROOT} && \
    MAKEFLAGS="-j${COLCON_PARALLEL}" \
    colcon build \
        --merge-install \
        --install-base ${ROS_ROOT} \
        --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
        --parallel-workers ${COLCON_PARALLEL} && \
    rm -rf /tmp/ros2_src

# colcon mixin/metadata (post-install, source tree is gone)
RUN colcon mixin add default \
        https://raw.githubusercontent.com/colcon/colcon-mixin-repository/master/index.yaml && \
    colcon mixin update && \
    colcon metadata add default \
        https://raw.githubusercontent.com/colcon/colcon-metadata-repository/master/index.yaml && \
    colcon metadata update

# ---------------------------------------------------------------------------
# Python ML stack: OpenCV headless, PyTorch/torchvision for Jetson
# (JetPack 6 / CUDA 12.6, aarch64), and Ultralytics.
# numpy is re-pinned at the end because opencv/ultralytics will happily
# upgrade it to 2.x otherwise.
# ---------------------------------------------------------------------------
RUN python3 -m pip install --no-cache-dir \
        opencv-python-headless && \
    python3 -m pip install --no-cache-dir --ignore-installed sympy && \
    python3 -m pip install --no-cache-dir \
        --index-url https://pypi.jetson-ai-lab.io/jp6/cu126 \
        torch torchvision && \
    python3 -m pip install --no-cache-dir \
        ultralytics \
        transforms3d && \
    python3 -m pip install --no-cache-dir --force-reinstall \
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

# ---------------------------------------------------------------------------
# Build Nav2 (and a few commonly-needed friends) from source against the
# Jazzy install under /opt/ros/jazzy.
#
# We use an overlay workspace at /opt/ros_overlay_src (removed after build)
# and --merge-install straight into /opt/ros/jazzy so the whole stack lives
# under one prefix.
# ---------------------------------------------------------------------------
ARG NAV2_BRANCH=jazzy
ARG BT_CPP_BRANCH=4.6.2

WORKDIR /opt/ros_overlay_src

RUN mkdir -p src && \
    printf '%s\n' \
        'repositories:' \
        '  navigation2:' \
        '    type: git' \
        '    url: https://github.com/ros-navigation/navigation2.git' \
        '    version: jazzy' \
        '  BehaviorTree.CPP:' \
        '    type: git' \
        '    url: https://github.com/BehaviorTree/BehaviorTree.CPP.git' \
        '    version: 4.6.2' \
        '  behaviortree_ros2:' \
        '    type: git' \
        '    url: https://github.com/BehaviorTree/BehaviorTree.ROS2.git' \
        '    version: humble' \
        '  ros2_control:' \
        '    type: git' \
        '    url: https://github.com/ros-controls/ros2_control.git' \
        '    version: jazzy' \
        '  ros2_control_cmake:' \
        '    type: git' \
        '    url: https://github.com/ros-controls/ros2_control_cmake.git' \
        '    version: master' \
        '  ros2_controllers:' \
        '    type: git' \
        '    url: https://github.com/ros-controls/ros2_controllers.git' \
        '    version: jazzy' \
        '  control_msgs:' \
        '    type: git' \
        '    url: https://github.com/ros-controls/control_msgs.git' \
        '    version: jazzy' \
        '  realtime_tools:' \
        '    type: git' \
        '    url: https://github.com/ros-controls/realtime_tools.git' \
        '    version: jazzy' \
        '  control_toolbox:' \
        '    type: git' \
        '    url: https://github.com/ros-controls/control_toolbox.git' \
        '    version: jazzy' \
        '  vision_opencv:' \
        '    type: git' \
        '    url: https://github.com/ros-perception/vision_opencv.git' \
        '    version: rolling' \
        '  xacro:' \
        '    type: git' \
        '    url: https://github.com/ros/xacro.git' \
        '    version: ros2' \
        '  robot_localization:' \
        '    type: git' \
        '    url: https://github.com/cra-ros-pkg/robot_localization.git' \
        '    version: jazzy-devel' \
        '  diagnostics:' \
        '    type: git' \
        '    url: https://github.com/ros/diagnostics.git' \
        '    version: ros2-jazzy' \
        '  angles:' \
        '    type: git' \
        '    url: https://github.com/ros/angles.git' \
        '    version: ros2' \
        '  nmea_msgs:' \
        '    type: git' \
        '    url: https://github.com/ros-drivers/nmea_msgs.git' \
        '    version: ros2' \
        '  geographic_info:' \
        '    type: git' \
        '    url: https://github.com/ros-geographic-info/geographic_info.git' \
        '    version: ros2' \
        '  usb_cam:' \
        '    type: git' \
        '    url: https://github.com/ros-drivers/usb_cam.git' \
        '    version: main' \
        '  twist_mux:' \
        '    type: git' \
        '    url: https://github.com/ros-teleop/twist_mux.git' \
        '    version: rolling' \
        '  twist_mux_msgs:' \
        '    type: git' \
        '    url: https://github.com/ros-teleop/twist_mux_msgs.git' \
        '    version: master' \
        '  generate_parameter_library:' \
        '    type: git' \
        '    url: https://github.com/PickNikRobotics/generate_parameter_library.git' \
        '    version: main' \
        '  backward_ros:' \
        '    type: git' \
        '    url: https://github.com/pal-robotics/backward_ros.git' \
        '    version: foxy-devel' \
        '  bond_core:' \
        '    type: git' \
        '    url: https://github.com/ros/bond_core.git' \
        '    version: ros2' \
        '  pal_statistics:' \
        '    type: git' \
        '    url: https://github.com/pal-robotics/pal_statistics.git' \
        '    version: humble-devel' \
        '  RSL:' \
        '    type: git' \
        '    url: https://github.com/PickNikRobotics/RSL.git' \
        '    version: main' \
        '  sdformat_urdf:' \
        '    type: git' \
        '    url: https://github.com/ros/sdformat_urdf.git' \
        '    version: rolling' \
        '  filters:' \
        '    type: git' \
        '    url: https://github.com/ros/filters.git' \
        '    version: ros2' \
        '  image_transport_plugins:' \
        '    type: git' \
        '    url: https://github.com/ros-perception/image_transport_plugins.git' \
        '    version: rolling' \
        '  kinematics_interface:' \
        '    type: git' \
        '    url: https://github.com/ros-controls/kinematics_interface.git' \
        '    version: jazzy' \
        '  tf_transformations:' \
        '    type: git' \
        '    url: https://github.com/DLu/tf_transformations.git' \
        '    version: main' \
        > nav2.repos

RUN vcs import src < nav2.repos && \
    for pkg in nav2_system_tests nav2_loopback_sim nav2_minimal_tb3_sim; do \
        find src -type d -name "$pkg" -exec touch {}/COLCON_IGNORE \; ; \
    done

# Install rosdep-provided deps for the overlay. Skip keys that are
# Noble-only or resolved via pip/manual installs.
RUN apt-get update && \
    . /opt/ros/${ROS_DISTRO}/setup.sh && \
    rosdep install --from-paths src --ignore-src -y --rosdistro ${ROS_DISTRO} \
        --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers rmw_connextdds \
                     ignition-cmake2 ignition-math6 python3-catkin-pkg-modules \
                     python3-lark-parser python3-empy \
                     behaviortree_cpp behaviortree_cpp_v3 \
                     gz-math7 gz-math-vendor gz-common5 gz-plugin2 \
                     gz-sim8 gz-transport13 ros_gz_bridge ros_gz_sim \
                     nav2_minimal_tb3_sim tf_transformations" \
    || true && \
    rm -rf /var/lib/apt/lists/*

ARG NAV2_COLCON_PARALLEL=4
RUN . /opt/ros/${ROS_DISTRO}/setup.sh && \
    MAKEFLAGS="-j${NAV2_COLCON_PARALLEL}" \
    colcon build \
        --merge-install \
        --install-base /opt/ros/${ROS_DISTRO} \
        --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
        --parallel-workers ${NAV2_COLCON_PARALLEL} && \
    rm -rf /opt/ros_overlay_src

WORKDIR /root/ros2_ws

# Setup entrypoint
COPY ros_entrypoint_jetson.sh /sbin/ros_entrypoint.sh
RUN chmod 755 /sbin/ros_entrypoint.sh

ENTRYPOINT ["/sbin/ros_entrypoint.sh"]
CMD ["bash"]
