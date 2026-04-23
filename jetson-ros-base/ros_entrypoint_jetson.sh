#!/bin/bash
set -e

# setup ros2 environment
source "/opt/ros/$ROS_DISTRO/setup.bash" --
if [ -f "/root/ros2_ws/install/local_setup.bash" ]; then
    source "/root/ros2_ws/install/local_setup.bash" --
fi

# Welcome information
echo "Jetson ROS2 Docker Image"
echo "------------------------"
echo 'ROS distro: ' $ROS_DISTRO
echo 'DDS middleware: ' $RMW_IMPLEMENTATION
echo "------------------------"
exec "$@"