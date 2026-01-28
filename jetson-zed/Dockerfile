ARG L4T_VERSION=l4t-r36.4.0
ARG IMAGE_NAME=nvcr.io/nvidia/l4t-jetpack:r36.4.0


FROM ${IMAGE_NAME}

ARG ZED_SDK_MAJOR=5
ARG ZED_SDK_MINOR=1
ARG ZED_SDK_PATCH=0
ARG L4T_MAJOR=36
ARG L4T_MINOR=4

# ROS2 distribution
ARG ROS2_DIST=humble

# ZED ROS2 Wrapper dependencies version
ARG XACRO_VERSION=2.0.8
ARG DIAGNOSTICS_VERSION=4.0.0
ARG AMENT_LINT_VERSION=0.12.11
ARG ROBOT_LOCALIZATION_VERSION=3.5.3
ARG ZED_MSGS_VERSION=4.2.2
ARG NMEA_MSGS_VERSION=2.0.0
ARG ANGLES_VERSION=1.15.0
ARG GEOGRAPHIC_INFO_VERSION=1.0.6
ARG POINTCLOUD_TRANSPORT_VERSION=1.0.18
ARG POINTCLOUD_TRANSPORT_PLUGINS_VERSION=1.0.11
ARG COB_VERSION=2.7.10
ARG RMW_CYCLONEDDS_VERSION=1.3.4


ENV DEBIAN_FRONTEND=noninteractive

RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    apt-get update && \
    apt-get install -q -y --no-install-recommends tzdata && \
    rm -rf /var/lib/apt/lists/*

# install packages
RUN apt-get update && apt-get install -q -y --no-install-recommends \
    dirmngr \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# setup sources.list
RUN echo "deb http://packages.ros.org/ros2/ubuntu jammy main" > /etc/apt/sources.list.d/ros2-latest.list

# setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

ENV ROS_DISTRO humble

# install ros2 packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-ros-core=0.10.0-1* \
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

# ZED SDK link
ENV ZED_SDK_URL="https://stereolabs.sfo2.cdn.digitaloceanspaces.com/zedsdk/${ZED_SDK_MAJOR}.${ZED_SDK_MINOR}/ZED_SDK_Tegra_L4T${L4T_MAJOR}.${L4T_MINOR}_v${ZED_SDK_MAJOR}.${ZED_SDK_MINOR}.${ZED_SDK_PATCH}.zstd.run"

# Check that this SDK exists
RUN if [ "$(curl -I "${ZED_SDK_URL}" -o /dev/null -s -w '%{http_code}\n' | head -n 1)" = "200" ]; then \
        echo "The URL points to something."; \
    else \
        echo "The URL does not point to a .run file or the file does not exist."; \
        exit 1; \
    fi

# Disable apt-get warnings
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F42ED6FBAB17C654 && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 42D5A192B819C5DA && \
  apt-get update && apt-get install -y --no-install-recommends apt-utils dialog 

ENV TZ=Europe/Paris

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \ 
  apt-get update && \
  apt-get install --yes lsb-release wget less udev sudo build-essential cmake python3 python3-dev python3-pip python3-wheel git jq libpq-dev zstd usbutils

RUN echo "# R${L4T_MAJOR} (release), REVISION: ${L4T_MINOR}" > /etc/nv_tegra_release && \
  apt-get update -y && \
  apt-get install -y --no-install-recommends zstd wget less cmake curl gnupg2 \
  build-essential python3 python3-pip python3-dev python3-setuptools libusb-1.0-0-dev \ 
  libgeographic-dev libdraco-dev zlib1g-dev -y && \
  pip3 install --extra-index-url https://pypi.org/simple protobuf && \
  wget -q --no-check-certificate -O ZED_SDK_Linux_JP.run \
  ${ZED_SDK_URL} && \
  chmod +x ZED_SDK_Linux_JP.run ; ./ZED_SDK_Linux_JP.run silent skip_tools skip_drivers && \
  rm -rf /usr/local/zed/resources/* && \
  rm -rf ZED_SDK_Linux_JP.run 

# Install the ZED ROS2 Wrapper
ENV ROS_DISTRO=${ROS2_DIST}

# Copy the sources in the Docker image
WORKDIR /root/ros2_ws/src
RUN git clone https://github.com/stereolabs/zed-ros2-wrapper.git

# Install missing dependencies from the sources
# WORKDIR /root/ros2_ws/src
# RUN wget https://github.com/ros/xacro/archive/refs/tags/${XACRO_VERSION}.tar.gz -O - | tar -xvz && mv xacro-${XACRO_VERSION} xacro && \
#     wget https://github.com/ros/diagnostics/archive/refs/tags/${DIAGNOSTICS_VERSION}.tar.gz -O - | tar -xvz && mv diagnostics-${DIAGNOSTICS_VERSION} diagnostics && \
#     wget https://github.com/ament/ament_lint/archive/refs/tags/${AMENT_LINT_VERSION}.tar.gz -O - | tar -xvz && mv ament_lint-${AMENT_LINT_VERSION} ament-lint && \
#     wget https://github.com/cra-ros-pkg/robot_localization/archive/refs/tags/${ROBOT_LOCALIZATION_VERSION}.tar.gz -O - | tar -xvz && mv robot_localization-${ROBOT_LOCALIZATION_VERSION} robot-localization && \
#     wget https://github.com/stereolabs/zed-ros2-interfaces/archive/refs/tags/${ZED_MSGS_VERSION}.tar.gz -O - | tar -xvz && mv zed-ros2-interfaces-${ZED_MSGS_VERSION} zed-ros2-interfaces && \
#     wget https://github.com/ros-drivers/nmea_msgs/archive/refs/tags/${NMEA_MSGS_VERSION}.tar.gz -O - | tar -xvz && mv nmea_msgs-${NMEA_MSGS_VERSION} nmea_msgs && \
#     wget https://github.com/ros/angles/archive/refs/tags/${ANGLES_VERSION}.tar.gz -O - | tar -xvz && mv angles-${ANGLES_VERSION} angles && \
#     wget https://github.com/ros-perception/point_cloud_transport/archive/refs/tags/${POINTCLOUD_TRANSPORT_VERSION}.tar.gz -O - | tar -xvz && mv point_cloud_transport-${POINTCLOUD_TRANSPORT_VERSION} point_cloud_transport && \
#     wget https://github.com/ros-perception/point_cloud_transport_plugins/archive/refs/tags/${POINTCLOUD_TRANSPORT_PLUGINS_VERSION}.tar.gz -O - | tar -xvz && mv point_cloud_transport_plugins-${POINTCLOUD_TRANSPORT_PLUGINS_VERSION} point_cloud_transport_plugins && \
#     wget https://github.com/ros2/rmw_cyclonedds/archive/refs/tags/${RMW_CYCLONEDDS_VERSION}.tar.gz -O - | tar -xvz && mv rmw_cyclonedds-${RMW_CYCLONEDDS_VERSION} rmw_cyclonedds && \
#     wget https://github.com/ros-geographic-info/geographic_info/archive/refs/tags/${GEOGRAPHIC_INFO_VERSION}.tar.gz -O - | tar -xvz && mv geographic_info-${GEOGRAPHIC_INFO_VERSION} geographic-info && \
#     cp -r geographic-info/geographic_msgs/ . && \
#     rm -rf geographic-info && \
#     wget https://github.com/4am-robotics/cob_common/archive/refs/tags/2.7.10.tar.gz -O - | tar -xvz && mv cob_common-${COB_VERSION} cob_common && \
#     cp -r cob_common/cob_srvs/ . && \
#     rm -rf cob_common
WORKDIR /root/ros2_ws

# RUN apt update && apt upgrade -y && \
# apt install software-properties-common -y && \
# add-apt-repository universe -y

# RUN curl -sSL raw.githubusercontent.com -o /usr/share/keyrings/ros-archive-keyring.gpg

# RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

RUN apt-get update && \
  rosdep update && \
  rosdep install --from-path src --ignore-src -y && \
  rm -rf /var/lib/apt/lists/*
  
RUN apt-get update && \
  apt-get install -y ros-humble-nmea-msgs \
  ros-humble-backward-ros
# Install cython
RUN python3 -m pip install --upgrade cython

# Build the dependencies and the ZED ROS2 Wrapper
WORKDIR /root/ros2_ws
  RUN /bin/bash -c "source /opt/ros/humble/setup.bash && \
    colcon build --symlink-install --cmake-args=-DCMAKE_BUILD_TYPE=Release --parallel-workers $(nproc) "

WORKDIR /root/ros2_ws

# Setup environment variables 
COPY ros_entrypoint_jetson.sh /sbin/ros_entrypoint.sh
RUN sudo chmod 755 /sbin/ros_entrypoint.sh

ENTRYPOINT ["/sbin/ros_entrypoint.sh"]
CMD ["bash"]
