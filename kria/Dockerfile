FROM ros:jazzy-ros-base
RUN apt-get update && apt-get install -y \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/Gold-Rush-Robotics/IEEE-2026-Prototypes.git -b localization_testing /root/IEEE-2026-Prototypes

WORKDIR /root/IEEE-2026-Prototypes/jazzy_ws

RUN /bin/bash -c "source /opt/ros/jazzy/setup.bash && \
    rosdep update && \
    rosdep install --from-paths src --ignore-src -r -y"

RUN apt install -y \
    ros-jazzy-usb-cam \
    can-utils \
    iproute2

# Install ros2 realsense
RUN git clone https://github.com/IntelRealSense/realsense-ros.git
RUN /bin/bash -c "source /opt/ros/jazzy/setup.bash && \
    cd realsense-ros && \
    git checkout jazzy && \
    cd .. && \
    mv realsense-ros src/ && \
    rosdep install --from-paths src --ignore-src -r -y"

RUN /bin/bash -c "source /opt/ros/jazzy/setup.bash && \
    colcon build --symlink-install"

# CMD ["/bin/bash", "-c", "slcand -o -c -s8 /dev/ttyACM0 can0 && sudo ip link set can0 up type can bitrate 1000000 && sudo ip link set can0 up && source /root/IEEE-2026-Prototypes/jazzy_ws/install/setup.bash && bash"]