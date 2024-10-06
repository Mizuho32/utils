#!/usr/bin/env bash

# Driver
if ! [ $(which nvidia-smi) ]; then
  sudo apt install -y $(nvidia-detector)
fi

# Docker
if ! [ $(which docker) ]; then
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
fi

# runtime
if ! [ -f /etc/apt/sources.list.d/nvidia-container-toolkit.list ]; then
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
 | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
 | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
 | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
fi

sudo apt update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
