FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CI=true
ENV USER=adios
ENV HOME=/home/adios
ENV PATH="/home/adios/.local/bin:${PATH}"

# Base dependencies
RUN apt update && apt install -y \
    sudo curl git ca-certificates locales fontconfig \
    && rm -rf /var/lib/apt/lists/*

# Locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create user
RUN useradd -m -s /bin/bash adios \
    && echo "adios ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy setup
COPY Ubuntu_Setup /Ubuntu_Setup
RUN chmod +x /Ubuntu_Setup/setup.sh

# Bake configuration
RUN HOME=/home/adios USER=adios /Ubuntu_Setup/setup.sh

# Switch to user
USER adios
WORKDIR /home/adios

CMD ["bash"]
