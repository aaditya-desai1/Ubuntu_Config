FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Basic tools needed to run the script
RUN apt update && apt install -y \
    sudo \
    curl \
    git \
    ca-certificates \
    locales \
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user (important!)
RUN useradd -m -s /bin/bash adios \
    && echo "adios ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER adios
WORKDIR /home/adios

# Copy bootstrap repo
COPY --chown=adios:adios Ubuntu_Setup ./Ubuntu_Setup
RUN chmod +x Ubuntu_Setup/setup.sh
