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

```shell
curl -fsSL https://get.docker.com | sh
```

Add your user to the docker group:

```shell
sudo usermod -aG docker $USER
```

Reload the session:

```shell
newgrp docker
```

Verify:

```shell
docker --version
docker compose version
```

---

## 2. Install Git

```shell
sudo apt update
sudo apt install -y git
```

Verify:

```shell
git --version
```

---

## 3. Clone the Repository

```shell
git clone https://github.com/ampaiva/ai-factory.git
cd ai-factory
```

---

## 4. Configure Environment Variables

```shell
cp .env.example .env
```

Edit:

```shell
nano .env
```

Example:

```
GITHUB_USER=your-user
ANTHROPIC_API_KEY=your_key_here
OPENAI_API_KEY=
WORKSPACE=/workspace
```

---

## 5. Start the AI Factory

```shell
docker compose up -d
```

Verify:

```shell
docker ps
```

You should see the container named:

```
ai-factory
```

---

## 6. Enter the Container

```shell
docker exec -it ai-factory bash
```

---

## 7. Verify Tools

```shell
git --version
gh --version
python3 --version
node --version
```

---

# Project Structure

```
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
```

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
