FROM ros:jazzy-ros-base

ARG USERNAME=ubuntu
ARG USER_UID=1000
ARG USER_GID=1000

# Install prerequisites
RUN apt-get update && apt-get install -y \
        sudo \
        apt-utils \
        openssh-client \
        gnupg2 \
        dirmngr \ 
        iproute2 \
        procps \
        lsof \
        htop \
        net-tools \
        psmisc \
        curl \
        tree \
        wget \
        rsync \
        ca-certificates \
        unzip \
        bzip2 \
        zip \
        nano \
        vim-tiny \
        less \
        jq \
        lsb-release \
        apt-transport-https \
        dialog \
        libc6 \
        libgcc1 \
        libkrb5-3 \
        libgssapi-krb5-2 \
        libicu-dev \
        liblttng-ust1 \
        libstdc++6 \
        zlib1g \
        locales \
        sudo \
        ncdu \
        man-db \
        strace \
        manpages \
        manpages-dev \
        libnss3 \
        init-system-helpers \
        libssl-dev \
        zsh \
        git \
        python3-pip \
        python3-poetry \
        pipx \
        libxml2 \
        libxml2-dev
        # libogre-1.12-dev
  RUN locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean


RUN locale-gen en_US.UTF-8

# Create the 'admin' user if not already exists
RUN if [ ! $(getent passwd ${USERNAME}) ]; then \
        groupadd --gid ${USER_GID} ${USERNAME} ; \
        useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} ; \
    fi

# Update 'admin' user
RUN echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && adduser ${USERNAME} video && adduser ${USERNAME} sudo

ENV USERNAME=${USERNAME}
ENV USER_GID=${USER_GID}
ENV USER_UID=${USER_UID}


RUN echo "source /etc/skel/.bashrc" >> /home/${USERNAME}/.bashrc && \
    echo "source /etc/skel/.profile" >> /home/${USERNAME}/.profile

RUN chsh --shell /bin/zsh ${USERNAME}; \
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /home/${USERNAME}/.oh-my-zsh && \
    cp /home/${USERNAME}/.oh-my-zsh/templates/zshrc.zsh-template /home/${USERNAME}/.zshrc && \
    sed -i 's/ZSH_THEME=.*/ZSH_THEME="devcontainers"/' /home/${USERNAME}/.zshrc && \
    echo "DISABLE_AUTO_UPDATE=true" >> /home/${USERNAME}/.zshrc && \
    echo "DISABLE_UPDATE_PROMPT=true" >> /home/${USERNAME}/.zshrc



RUN curl -fsSL --insecure https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli

# Add docker group
RUN groupadd --system docker
RUN usermod -aG docker ${USERNAME}


####################
# Preload ROS Deps #
####################
# Install metapackage #
RUN mkdir -p /tmp/workspace/src
WORKDIR /tmp/workspace
COPY metapackage /tmp/workspace/src/metapackage

# Install ZED Msgs #
RUN git clone https://github.com/stereolabs/zed-ros2-interfaces.git /tmp/workspace/src/zed_interfaces

# Install Zenoh_rmw #
RUN git clone https://github.com/ros2/rmw_zenoh.git /tmp/workspace/src/rmw_zenoh

# Build Workspace #
RUN apt-get update && rosdep update && rosdep install --from-paths /tmp/workspace/src --ignore-src -r -y
RUN /bin/bash -c "source /opt/ros/$ROS_DISTRO/setup.bash && colcon build --packages-select zed_msgs"

# Install R2S #
WORKDIR /tmp/
RUN git clone https://github.com/mjcarroll/r2s.git
WORKDIR /tmp/r2s
RUN poetry install
RUN echo 'alias r2s="poetry run r2s"' >> ~/.zshrc

# Install robot-folders #
RUN pipx install robot-folders
RUN echo "source ${HOME}/.local/share/pipx/venvs/robot-folders/bin/rob_folders_source.sh" >> ~/.bashrc


#######################
# Install Python deps #
#######################

# RUN pip3 install -r /tmp/workspace/requirements.txt



######################
# Docker Permissions #
######################
RUN echo "#!/bin/sh\n\
sudoIf() { if [ \"\$(id -u)\" -ne 0 ]; then sudo \"\$@\"; else \"\$@\"; fi }\n\
SOCKET_GID=\$(stat -c '%g' /var/run/docker.sock) \n\
if [ \"${SOCKET_GID}\" != '0' ]; then\n\
    if [ \"\$(cat /etc/group | grep :\${SOCKET_GID}:)\" = '' ]; then sudoIf groupadd --gid \${SOCKET_GID} docker-host; fi \n\
    if [ \"\$(id ${USERNAME} | grep -E \"groups=.*(=|,)\${SOCKET_GID}\(\")\" = '' ]; then sudoIf usermod -aG \${SOCKET_GID} ${USERNAME}; fi\n\
fi\n\
exec \"\$@\"" > /usr/local/share/docker-init.sh \
&& chmod +x /usr/local/share/docker-init.sh

# VS Code overrides ENTRYPOINT and CMD when executing `docker run` by default.
# Setting the ENTRYPOINT to docker-init.sh will configure non-root access to
# the Docker socket if "overrideCommand": false is set in devcontainer.json.
# The script will also execute CMD if you need to alter startup behaviors.
USER ${USERNAME}

ENTRYPOINT [ "/usr/local/share/docker-;init.sh" ]
CMD [ "sleep", "infinity" ]
