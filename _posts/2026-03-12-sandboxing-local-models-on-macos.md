---
title: 'Sandboxing local models on macOS'
excerpt: >
  Default-deny sandbox profiles for inference and agents, plus local Qwen3.5 and a QEMU VM.
redirect_from:
  - /sandboxed-ai
related:
  - _posts/2026-10-05-offline-local-inference-on-macos.md
---

The recently released [Qwen3.5 family][0] advances the capabilities of
open-weights multi-modal models: rumors are they're _exceptionally_ good
for their size. The 35B-A3B and 27B variants are small enough to run on 64GB of
unified memory (especially if quantized). So, I decided to give them a try.

### Sandboxing

Being wary of prompt injection and the probabilistic nature of LLMs, I usually
confine AI agents to ephemeral VMs, where they can wreak havoc in YOLO mode
(`--dangerously-skip-permissions`). With hosted models, this is easy: the VM
just needs internet access and remains isolated from the host. To run local
models on the VM instead, we'd need to let it access the GPU and install
compatible drivers. My only device with 64GB of RAM is a MacBook, and I run
Linux VMs on it, so I'd need to find Linux drivers compatible with Apple
hardware (if they exist).

A pragmatic approach is to:

1. Sandbox model inference (since parsing GGUF models has led to [code
   execution vulnerabilities][13]);
1. either sandbox the _client_ as well, for quick explorations; or
1. keep the agents in a VM and forward their API access to the local model.

The go-to sandbox on macOS is [`sandbox-exec`][1]. Apple has marked it as
deprecated years ago, but it continues to work because it powers [App
Sandbox][4], the sandboxing mechanism used by the Apple Store. It's a weird
beast, configurable through arcane profiles written in a Scheme dialect (which
got a lot easier to write with LLMs). Now that the big AI companies are using
it to sandbox their tools[^caveat], it is seeing a renaissance. I have
been using it for a while to sandbox `lazyvim` when running outside a VM, so
that it cannot reach the internet or make changes outside `~/work`.

Here, we'll take a similar approach to sandbox model inference down to its
minimal capabilities (essentially, GPU and driver access) and then sandbox the
agents to run offline and within the well-defined boundaries of a workspace.
Importantly, all sandbox profiles have `default deny`, so we can allow exactly
what we need and deny the rest.

[^caveat]: With the important caveat that often the agent can _disable_ the
    sandbox at runtime.

### Sandboxing profiles

<div class="hint" markdown="1">

  If you want to jump to the code, you'll find everything at the
  [`sandboxed-ai` GitHub repository][2].

</div>

#### Server

We'll use [`llama-server`][3] to do model inference, which also provides
OpenAI-compatible REST APIs for the clients. The [sandbox file][12] I came up
with through trial and error only allows access to the executable, the model
weights, the GPU and its drivers, and some cache directories. In addition,
`llama-server` can bind to port `8080` to serve its APIs, but cannot reach the
network (outbound).

The result is a simple [`sandbox.sh`][5] script (no external dependencies)
that calls `sandbox-exec` and spins up the server. All additional arguments are
forwarded to `llama-server`. Because the sandbox prevents network access, the
script does some special handling of the `--model` parameter: if a model
doesn't exist locally, it will fetch it (outside the sandbox) through `curl`.

```bash
./sandbox.sh llama-server --model unsloth/Qwen3.5-9B-GGUF:Qwen3.5-9B-Q8_0.gguf
```

We can now run Qwen3.5. Here, I am using the [unsloth][6] quantized model and
including their recommended sampling parameters:

```bash
$ ./sandbox.sh llama-server \
    --model unsloth/Qwen3.5-35B-A3B-GGUF:UD-Q4_K_XL.gguf \
    --ctx-size 16384 \
    --temp 0.7 \
    --top-p 0.8 \
    --top-k 20 \
    --min-p 0.00 \
    --chat-template-kwargs '{"enable_thinking":false}'

Starting sandboxed llama-server:
  binary:        /nix/store/l4xdm13zilm71n1jad95rpzk49h57is5-llama-cpp-metalkit-0.0.0/bin/llama-server
  model:         /Users/aldur/Work/local-opencode/.opencode/models/unsloth/Qwen3.5-35B-A3B-GGUF/Qwen3.5-35B-A3B-UD-Q4_K_XL.gguf
  alias:         Qwen3.5-35B-A3B-GGUF
  port:          8080
  extra:         --ctx-size 16384 --temp 0.7 --top-p 0.8 --top-k 20 --min-p 0.00 --chat-template-kwargs {"enable_thinking":false}

...
```

#### Local clients

With the model ready, we can now chat with it. To do that, I have also prepared
sandbox profiles for:

1. [`simonw/llm`][7], which I use to run quick queries;
1. [`opencode`][8], which I use interactively.

```bash
$ ./sandbox.sh llm
Hello there!
^D
Hello! How can I help you today?
```

The `sandbox.sh` script automatically takes care of the configuration files
that both tools require to interface with `llama-server` (you'll find an
`opencode.json` in the script directory).

The sandbox profiles are quite hardened: they don't allow network outbound,
restrict all writes to a single workspace directory (`-w`), and whitelist only
selected executables (restricting allowed tools). Cache files are written
alongside the script. Because of the sandbox restrictions, a few things will
break: `opencode web`, for instance, because it requires remote access to load
the frontend assets. On the other hand, the sandbox guarantees both integrity
and confidentiality on bare macOS, guaranteeing that the computation remains
local and preventing `opencode` from leaking your prompts[^leak].

[^leak]: In the default configuration, the `small_model` configuration
    parameter [uploads prompts to OpenCode's servers][9] to generate session titles.

#### In a QEMU VM

When I need to do anything more than quick checks/chats, I just spin up an
ephemeral QEMU VM. My [`qemu-vm`][10] script uses SLiRP user network[^slirp],
so `llama-server` from the host is available at `10.0.2.2:8080`:

[^slirp]: SLiRP user network isn't ideal for isolation because it
         doesn't firewall the VM, which appears to macOS as a process that can
         access `localhost` sockets. The proper solution is to use TAP bridges,
         but we'll leave that to another post.

```bash
qemu-vm -d $(pwd) -- -ephemeral
Starting VM...
...
qemu-nixos login: aldur (automatic login)
[I] aldur@qemu-nixos ~> curl http://10.0.2.2:8080/health
{"status":"ok"}
[I] aldur@qemu-nixos ~> cat opencode.json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "llama/Qwen3.5-35B-A3B-GGUF",
  "provider": {
    "llama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama.cpp (local)",
      "options": {
        "baseURL": "http://10.0.2.2:8080/v1",
        "apiKey": "dummy"
      },
      "models": {
        "Qwen3.5-35B-A3B-GGUF": {
          "name": "Qwen3.5-35B-A3B-GGUF",
          "tool_call": true
        }
      }
    }
  },
  "autoupdate": false
}
[I] aldur@qemu-nixos ~> nix run github:nixos/nixpkgs#opencode
                                   ▄
  █▀▀█ █▀▀█ █▀▀█ █▀▀▄ █▀▀▀ █▀▀█ █▀▀█ █▀▀█
  █  █ █  █ █▀▀▀ █  █ █    █  █ █  █ █▀▀▀
  ▀▀▀▀ █▀▀▀ ▀▀▀▀ ▀▀▀▀ ▀▀▀▀ ▀▀▀▀ ▀▀▀▀ ▀▀▀▀

  Session   Greeting and quick check-in

Hello Qwen! How are you doing today?
I'm doing well, thanks for asking! How can I help you today?
```

### Test drives

On a MacBook Pro with an M3 Max CPU and 64GB of RAM, `Qwen3.5-35B-A3B-Q8_0` is
quick enough that any prompt feels snappy and interactive, even with thinking
enabled. When using `opencode`, it churns for a few seconds through the initial
big prompt (on a cold cache) and is then able to use tools and read files
quickly enough. Although the quality of results is lower than frontier hosted
models, it's a big step forward: this relatively small model can make small,
interactive changes. Plus, the OCR capabilities of the whole family are
impressive.

I also gave `Qwen3.5-27B-Q8_0.gguf` a shot, which trades inference speed for
better accuracy. To test drive it, I stuck to the default parameters, fed it a
draft of this blog post, then asked for edits[^writing].
[Here's][11] the transcript of the session, the server logs and the model
info. Producing the output required more than 10 minutes of computation and
used about 15% of battery charge, with fans spinning and GPU at 100%
utilization. The task was relatively easy, and the results are satisfying: I
integrated almost all of its suggestions.

Thank you for reading and 'til next time! 👋

[^writing]: As a reminder, all writing on this blog (typos and weird sentences
    included) is mine. Writing is thinking and I don't see the point in having
    the LLM think for me.

#### Footnotes

[0]: https://qwen.ai/blog?id=qwen3.5
[1]: https://man.freebsd.org/cgi/man.cgi?query=sandbox-exec&sektion=1&manpath=macOS+26.3
[2]: https://github.com/aldur/sandboxed-ai/tree/master
[3]: https://github.com/ggml-org/llama.cpp
[4]: https://developer.apple.com/documentation/security/app-sandbox
[5]: https://github.com/aldur/sandboxed-ai/blob/master/sandbox.sh
[6]: https://unsloth.ai/docs/models/qwen3.5
[7]: https://github.com/simonw/llm
[8]: https://opencode.ai
[9]: https://github.com/anomalyco/opencode/issues/8609
[10]: https://github.com/aldur/dotfiles?tab=readme-ov-file#qemu-vm-1
[11]: https://gist.github.com/aldur/94378954caa0829bc5cb5dcca6962379
[12]: https://github.com/aldur/sandboxed-ai/blob/master/llama-server.sb
[13]: https://github.com/ggml-org/llama.cpp/security#untrusted-inputs
