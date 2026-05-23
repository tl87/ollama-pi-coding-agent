# Base image
FROM fedora:latest

# Set timezone
ENV TZ=Europe/Copenhagen

# Create user "pi"
RUN useradd -m -s /bin/bash pi

# Install required packages
RUN dnf install -y \
  curl \
  ca-certificates \
  vim \
  nodejs \
  && dnf clean all

# Install pi-coding-agent
RUN cd /home/pi && \
    curl -fsSL https://pi.dev/install.sh | sh

# Install Ollama
RUN cd /home/pi && \
    curl -fsSL https://ollama.com/install.sh | sh

# Create config directories
RUN mkdir -p /home/pi/.pi/agent && \
    mkdir -p /home/pi/.ollama && \
    mkdir -p /home/pi/.pi/skills && \
    mkdir -p /home/pi/.pi/projects && \
    chown -R pi:pi /home/pi

# Copy provider config
COPY ./src/models/models.json /home/pi/.pi/agent/models.json
RUN chown pi:pi /home/pi/.pi/agent/models.json

# Copy skills
COPY ./src/skills /home/pi/.pi/agent/skills
RUN chown -R pi:pi /home/pi/.pi/agent/skills

# Copy AGENTS.md
COPY ./src/AGENTS.md /home/pi/projects/AGENTS.md
RUN chown -R pi:pi /home/pi/projects/AGENTS.md

# Switch to user pi
USER pi

# Expose Ollama API port
EXPOSE 11434

# Start Ollama server by default
CMD ["ollama", "serve"]
