FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CI=true
ENV PATH="/home/adios/.local/bin:${PATH}"

# Base system dependencies (root)
RUN apt update && apt install -y \
    sudo curl git ca-certificates locales fontconfig \
    && rm -rf /var/lib/apt/lists/*

# Locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create non-root user
RUN useradd -m -s /bin/bash adios \
    && echo "adios ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy setup as root
WORKDIR /root
COPY Ubuntu_Setup /root/Ubuntu_Setup
RUN chmod +x /root/Ubuntu_Setup/setup.sh

# 🔥 Bake everything into the image
RUN /root/Ubuntu_Setup/setup.sh

# Runtime user
USER adios
WORKDIR /home/adios

CMD ["bash"]
