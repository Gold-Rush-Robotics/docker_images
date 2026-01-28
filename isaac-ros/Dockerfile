FROM nvcr.io/nvidia/isaac/ros:x86_64-ros2_humble_6f2a6bddf70fcd928f08e874635efe43

# Set locale
RUN sudo apt update && sudo apt install locales -y && \
sudo locale-gen en_US en_US.UTF-8 && \
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8

# ENV LANG en_US.UTF-8
# ENV LC_ALL en_US.UTF-8

RUN sudo apt update && sudo apt install -y \
gnupg \
wget \
software-properties-common && \
sudo add-apt-repository universe

RUN wget -qO - https://isaac.download.nvidia.com/isaac-ros/repos.key | sudo apt-key add - && \
grep -qxF "deb https://isaac.download.nvidia.com/isaac-ros/release-3 $(lsb_release -cs) release-3.0" /etc/apt/sources.list || \
echo "deb https://isaac.download.nvidia.com/isaac-ros/release-3 $(lsb_release -cs) release-3.0" | sudo tee -a /etc/apt/sources.list

RUN sudo apt-get update && sudo apt-get install -y  \
ros-humble-isaac-ros-apriltag \
ros-humble-isaac-ros-visual-slam \
ros-humble-isaac-ros-visual-slam-interfaces \
ros-humble-isaac-ros-cumotion \
ros-humble-isaac-ros-cumotion-moveit \
ros-humble-isaac-ros-h264-decoder \
ros-humble-isaac-ros-h264-encoder \
ros-humble-isaac-ros-image-pipeline \
ros-humble-isaac-ros-image-proc \
ros-humble-isaac-ros-stereo-image-proc \
ros-humble-isaac-ros-visual-global-localization \
ros-humble-isaac-mapping-ros \
ros-humble-isaac-ros-scene-recorder \
ros-humble-isaac-ros-vda5050-nav2-client \
ros-humble-isaac-ros-nvblox \
ros-humble-isaac-ros-rtdetr \
ros-humble-isaac-ros-detectnet \
ros-humble-isaac-ros-yolov8




