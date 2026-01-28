FROM ros:jazzy-ros-base

RUN apt-get update \
    && apt-get -y install --no-install-recommends software-properties-common git libusb-1.0-0-dev wget zsh python3-colcon-common-extensions python3 python3-pip git

RUN sudo pip3 install --break-system-packages adafruit-circuitpython-pca9685