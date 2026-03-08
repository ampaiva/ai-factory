FROM python:3.11-slim

# instala dependências como root
RUN apt-get update && apt-get install -y \
    git \
    curl \
    nodejs \
    npm \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
 | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
RUN chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
 | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
RUN apt-get update && apt-get install -y gh

# criar usuário
RUN useradd -ms /bin/bash factory \
 && mkdir -p /home/factory/.claude \
 && chown -R factory:factory /home/factory

ENV CI=true
ENV CLAUDE_NON_INTERACTIVE=1
ENV PIP_NO_CACHE_DIR=1

USER factory
WORKDIR /workspace

COPY requirements.txt .
RUN pip install --upgrade pip setuptools wheel \
 && pip install -r requirements.txt

RUN claude --print "init" >/dev/null 2>&1 || true
