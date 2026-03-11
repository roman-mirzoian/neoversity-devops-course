#!/bin/bash

set -e

echo "Updating package list..."
sudo apt update

# Install Docker
if command -v docker &> /dev/null
then
    echo "Docker is already installed."
else
    echo "Installing Docker..."
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
fi

# Install Docker Compose
if command -v docker-compose &> /dev/null
then
    echo "Docker Compose is already installed."
else
    echo "Installing Docker Compose..."
    sudo apt install -y docker-compose
fi

# Install Python 3.9+
if command -v python3 &> /dev/null
then
    PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    echo "Python version $PYTHON_VERSION detected."
else
    echo "Installing Python..."
    sudo apt install -y python3 python3-pip
fi

# Ensure pip installed
if ! command -v pip3 &> /dev/null
then
    echo "Installing pip..."
    sudo apt install -y python3-pip
fi

# Install Django
if pip3 show django &> /dev/null
then
    echo "Django is already installed."
else
    echo "Installing Django..."
    pip3 install django
fi

echo "All tools are ready."