# OllamaStack

Setup [Ollama](https://github.com/jmorganca/ollama) stack on macOS.

- [OllamaStack](#ollamastack)
  - [Prerequisites](#prerequisites)
  - [Diagram](#diagram)
  - [Quickstart](#quickstart)
    - [Demo](#demo)

## Prerequisites
* A [Metal capable](https://support.apple.com/en-us/102894) Mac device.
* [Mods](https://github.com/charmbracelet/mods): AI for the command line, built for pipelines.
* [Docker](https://www.docker.com/products/docker-desktop): The fastest way to containerize applications.

## Diagram

```mermaid
graph LR;
    subgraph Host
      subgraph CLI
        B(Mods)
        G(Collector)
      end
      subgraph Server
        C(Ollama)
        D[Metal]
      end
    end
    subgraph Container
      E(LiteLLM Proxy)
      F(Ollama Web UI)
      H(Prometheus)
      I(Grafana)
    end
    A(User) --> |Terminal|B;
    A --> |Browser|F;
    B --> |OpenAI API|E;
    E --> |REST API|C;
    F --> |REST API|C;
    C-. Link .-> D;
    H --> |Client API|G;
    I --> |Data Source|H;
```

## Quickstart

```bash
$ git clone https://github.com/yeahdongcn/OllamaStack.git
$ cd OllamaStack
$ ./start.sh
$ ./stop.sh
```

### Demo

![633462](https://github.com/yeahdongcn/OllamaStack/assets/2831050/1290b08a-6636-493e-8ad4-edcb18971198)

<img width="1277" alt="Screenshot 2024-01-31 at 11 45 31" src="https://github.com/yeahdongcn/OllamaStack/assets/2831050/3370513b-8920-4ee1-bc7c-0f2e4c4e8c40">
