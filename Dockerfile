FROM osrf/ros:humble-desktop

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Example of installing programs
RUN apt-get update \
  && apt-get install -y \
  nano \
  && rm -rf /var/lib/apt/list/*

# Apps to test the devices
RUN apt-get update \
  && apt-get install -y \
  evtest \
  jstest-gtk \
  python3-serial \
  && rm -rf /var/lib/apt/list/*

# Install gazebo harmonic dependencies
RUN apt-get update \
  && apt-get install -y \
  curl \
  lsb-release \
  gnupg \
  && rm -rf /var/lib/apt/list/*

# add user to dialout group to access serial devices
RUN usermod -aG dialout ${USERNAME}

# Add Gazebo repository
RUN curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null

# Install Gazebo Harmonic
RUN apt-get update \
  && apt-get install -y \
  gz-harmonic \
  && rm -rf /var/lib/apt/lists/*

# Set up the environment
ENV GZ_VERSION=harmonic
ENV GZ_RESOURCE_PATH=/usr/share/gazebo-${GZ_VERSION}

# Example of copying a file
COPY config/ /site_config/

# Create a non-root user
ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
  && mkdir /home/$USERNAME/.config && chown $USER_UID:$USER_GID /home/$USERNAME/.config

# Set up sudo
RUN apt-get update \
  && apt-get install -y sudo \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
  && chmod 0440 /etc/sudoers.d/$USERNAME \
  && rm -rf /var/lib/apt/lists/*

# Copy the entrypoint and bashrc scripts so we have 
# our container's environment set up correctly
COPY entrypoint.sh /entrypoint.sh
COPY bashrc /home/${USERNAME}/.bashrc

# Set up entrypoint and default command
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
CMD ["bash"]