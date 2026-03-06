# AI Factory

Personal environment to run autonomous coding agents overnight.

This repository contains everything required to recreate the development
environment from zero in case the machine is lost or replaced.

---

# Restore Machine (From Zero)

These instructions restore the entire AI Factory on a fresh Linux machine.
Tested on Debian / Ubuntu.

---

## 1. Install Docker

Run:

curl -fsSL https://get.docker.com | sh

Add your user to the docker group:
    
sudo usermod -aG docker $USER

Reload the session:

newgrp docker

Verify:

docker --version
docker compose version

---

## 2. Install Git

sudo apt update
sudo apt install -y git

Verify:

git --version

---

## 3. Clone the Repository

git clone https://github.com/ampaiva/ai-factory.git

cd ai-factory

---

## 4. Configure Environment Variables

cp .env.example .env

Edit:

nano .env

Example:

GITHUB_USER=your-user
ANTHROPIC_API_KEY=your_key_here
OPENAI_API_KEY=
WORKSPACE=/workspace

---

## 5. Start the AI Factory

docker compose up -d

Verify:

docker ps

You should see the container named:

ai-factory

---

## 6. Enter the Container

docker exec -it ai-factory bash

---

## 7. Verify Tools

git --version
gh --version
python3 --version
node --version

---

# Project Structure

ai-factory
│
├─ docker-compose.yml
├─ .env.example
├─ Makefile
├─ bootstrap.sh
│
├─ agents/
│   └─ README.md
│
├─ scripts/
│   └─ setup.sh
│
└─ workspace/
    └─ README.md

---

# Disaster Recovery Test

Every few months perform a recovery test on a fresh machine to ensure
these instructions still work.

---

# Goal

Turn this machine into a **nightly AI coding factory** that:

1. Reads GitHub issues
2. Plans implementation using Claude
3. Writes code
4. Runs tests
5. Opens Pull Requests automatically
