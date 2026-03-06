#!/bin/bash
set -e

echo "Installing base dependencies..."

sudo apt update
sudo apt install -y git curl

echo "Installing Docker..."
curl -fsSL https://get.docker.com | sh

sudo usermod -aG docker $USER

echo "Bootstrap completed."
echo "Log out and log in again before running docker."