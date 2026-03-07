FROM python:3.11

RUN apt update && apt install -y \
    git \
    curl \
    nodejs \
    npm

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
 | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg

RUN chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
 | tee /etc/apt/sources.list.d/github-cli.list

RUN apt update && apt install -y gh

RUN ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts

WORKDIR /workspace

COPY requirements.txt .
ENV PIP_NO_CACHE_DIR=1
RUN pip install --upgrade pip setuptools wheel
RUN pip install -r requirements.txt