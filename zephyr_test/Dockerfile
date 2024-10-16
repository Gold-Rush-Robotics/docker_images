FROM ubuntu:22.04

LABEL maintainer="david@robodrome.nl"
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
ARG WGET_ARGS="-q --show-progress --progress=bar:force:noscroll --no-check-certificate"

RUN apt-get update > /dev/null \
    && apt-get upgrade --yes > /dev/null \
    && apt-get install --no-install-recommends --yes > /dev/null \
    ca-certificates \
    apt-utils \
    cmake \
    curl \
    gnupg2 \
    gpg \
    lsb-release \
    wget \
    git \
    sudo \
    vim \
    ssh

RUN apt-get install --no-install-recommends --yes > /dev/null \
    ninja-build gperf \
    ccache dfu-util \
    device-tree-compiler \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-tk \
    python3-wheel \
    xz-utils \
    file \
    make \
    gcc \
    gcc-multilib \
    g++-multilib \
    libsdl2-dev \
    libmagic1 \
    && rm -rf /var/lib/apt/lists/*

ARG USERNAME=zephyr
ARG UID=1000
ARG GID=1000

RUN useradd -m ${USERNAME} \
    && echo "$USERNAME:$USERNAME" | chpasswd \
    && usermod --shell /bin/bash ${USERNAME} \
    && usermod -aG sudo ${USERNAME} \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && usermod  --uid ${UID} ${USERNAME} \
    && groupmod --gid ${GID} ${USERNAME} \
    && adduser ${USERNAME} dialout \
    && adduser ${USERNAME} plugdev

ENV PATH=/home/"$USERNAME"/.local/bin:"$PATH"

# install colcon
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
     | tee /etc/apt/sources.list.d/ros2.list > /dev/null \
    && apt update > /dev/null \
    && apt install --yes python3-colcon-common-extensions > /dev/null

# install openocd
RUN apt update > /dev/null \
    && apt install --yes \
    openocd \
    minicom > /dev/null

# install zephyr
ARG ZEPHYR_REMOTE_BRANCH=v3.2
USER $USERNAME
ENV PATH=/home/"$USERNAME"/.local/bin:"$PATH"
WORKDIR /home/${USERNAME}

RUN pip3 install --user -U west catkin_pkg lark-parser \
    && west init --mr ${ZEPHYR_REMOTE_BRANCH}-branch \
    && west update \
    && west zephyr-export \
    && pip3 install --user -r ./zephyr/scripts/requirements.txt

# install zephyr sdk
ARG ZEPHYR_SDK_VERSION=0.15.2
RUN wget ${WGET_ARGS} https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64.tar.gz -O - \
    | tar -xz zephyr-sdk-${ZEPHYR_SDK_VERSION} \
    && sudo -E -- bash -c './zephyr-sdk-${ZEPHYR_SDK_VERSION}/setup.sh -c && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.cmake'

ENV ZEPHYR_TOOLCHAIN_VARIANT=zephyr
 
