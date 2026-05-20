# Ollama + pi‑coding‑agent (Podman Environment)

This project provides a reproducible Podman‑based development environment for running **Ollama** together with **pi‑coding‑agent**, using a non‑root user (`pi`) and automatic model setup.

It includes:

- A custom Dockerfile  
- A `models.json` provider configuration  
- A management script (`podman-ollama.sh`)  
- Volume mounting of your working directory  
- Node.js + npm + pi‑coding‑agent installed globally  

## ⚠️ Disclaimer

**This repository and the derived guidelines are for getting started - feel free to modify as you see fit !**

**Users must verify all operational commands and security policies against current, official documentation. I AM NOT RESPONSIBLE FOR ANY DAMAGES OR ANYTHING ELSE !!!**

**There are no guardrails in Pi-coding-agent, so don't ask the model to do stupid things - you have been warned !**

## 📁 Project Structure

```
.
├── Dockerfile
├── models
│   └── models.json
├── podman-ollama.sh
├── README.md
└── skills
    ├── cyber-security-specialist.md
    ├── devops-engineer.md
    ├── midjourney-prompt-generator.md
    ├── no-bs.md
    ├── senior-linux-system-administrator.md
    └── senior-python-developer.md
```

### Dockerfile

Builds a container image that includes:

- Ollama
- Node.js + npm
- Global install of `@earendil-works/pi-coding-agent`
- A non‑root user named `pi`
- Custom provider configuration

### models.json

Defines custom providers and models for pi‑coding‑agent:

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434/v1",
      "api": "openai-completions",
      "apiKey": "ollama",
      "models": [
        { "id": "llama3.1:8b" },  <-- here
        { "id": "gemma4:e2b" }    <-- and here
      ]
    }
  }
}

```

### podman-ollama.sh

A helper script to manage the container:

- build – build the image
- start – start the container and attach to it
- stop – stop the container
- attach – open a shell inside the container
- clean – remove the container

### Getting Started

1. Make the script executable:

```bash
chmod +x podman-ollama.sh
```

2. Build the Image:

```bash
./podman-ollama.sh build
```

This build the image named `ollama-pi-agent`.

3. Start the container:

```bash
./podman-ollama.sh start
```

Behavior:

- If the container does not exist, it will be created, started, and you will be attached to it.
- If the container already exists, it will simply start and attach.

The container exposes: `http://localhost:11434`.

This is the Ollama API endpoint.

When you run the start-option, the container will also attach itself. If that is not the case, use the attach-option:

```bash
./podman-ollama.sh attach
```

4. Pull some LLM's

If this is the first time running the container, there are two options to pull the LLM's.

Option 1 - use the shell script:

```bash
./podman-ollama.sh models
```

Option 2 - from inside the container, run the commands below:

```bash
ollama pull gemma4:e2b
ollama pull qwen3:14B
ollama pull qwen3.5:4b
ollama pull qwen3.5:2b
ollama pull qwen3.5:0.8b
ollama pull gpt-oss:20b
```

You can add more models or modify it, but you need to remember to also change the `models.json` accordingly.

5. When done, you simply stop the container:

```bash
./podman-ollama.sh stop
```

6. To remove the container and clean up, you can use:

```bash
./podman-ollama.sh clean
```

### AGENT.md

Give pi project instructions. Pi loads context files at startup. Add an AGENTS.md file to tell it how to work in a project:

# Project Instructions

- Run `npm run check` after code changes.
- Do not run production migrations locally.
- Keep responses concise.

Pi loads:

- ~/.pi/agent/AGENTS.md for global instructions
- AGENTS.md or CLAUDE.md from parent directories and the current directory

Restart pi, or run /reload, after changing context files.

### models.json

Inside the container (`pi-coding-agent`), it automatically loads: `/home/pi/.pi/agent/models.json`.

### Volume mount

The container automatically mounts your current working directory into:

```bash
/workspace
```

---
