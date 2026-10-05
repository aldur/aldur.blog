---
title: 'Offline local inference on macOS'
date: 2026-10-05
---

Local inference allows running agentic workflows over sensitive data (e.g.,
financial, health) where both the computation and the data remain entirely
offline. That's my number one reason for it: _confidentiality_.

Ensuring that (rogue) agents don't wonder around is a [hot topic][0]. My
solution for it pairs:

1. [Sandboxed inference on
   macOS](/_posts/2026-03-12-sandboxing-local-models-on-macos.md), which uses
   `seatbelt` to harden the runtime and prevent remote connections.
1. An _offline_ [Apple
   container](/_posts/2026-06-11-nixos-for-apple-container.md) that bundles
   `pi` and a few useful tools in a NixOS image.

<p align="center" markdown="1">
<picture class="text-align-center" markdown="1">
  <img src="{% link images/sandboxed-ai.svg %}" alt="A diagram showing a sandboxed llama-cpp server and an offline pi agent running in Apple container, everything under macOS." class="centered inverted">
</picture>
<small>_Zebra stripes represent sandboxing._</small>
</p>

### Threat modeling

`llama-cpp` runs through `seatbelt`: it can only read the model files, cannot
reach the internet (models are downloaded beforehand), and adds a level of
defense in case of vulnerabilities in the inference engine (e.g., the Jinja
template parsing). `pi` runs in a "airgapped" Apple container that has no DNS
and no networking. It communicates with `llama-cpp` over a Unix socket mounted
within the container. A small relay converts the Unix socket into TCP for `pi`
to connect to. `pi` knocks off tasks through the workspace mounted read/write
within the container.

In terms of threat modeling, this setup is probably: 1. good enough; 2. likely
not bulletproof: just this week we saw a [new KVM escape][3]. The risks on the
`llama-cpp` side are probably small because of `seatbelt` and a reduced attack
surface. Things are different on the `pi` side. The Apple container runtime has
had some [moderate issues][4], but I have done some light red-teaming against
it and it now holds relatively well. The biggest attack surface is the mounted
workspace. An agent can "poison" it and then try exfiltration through macOS
(e.g., by introducing a malicious `git` hook). To solve that, I both reduce
degrees of freedom within the container (e.g., by preventing an agent from
writing into the `.git` folder) and by hardening macOS and its configuration
(e.g., `git` hooks are entirely disabled).

It's a cat-and-mouse game: we do our best to stay ahead, balancing security and
practicality. For instance, we could use SSH to `scp` the workspace into the
container and review any changes before pulling them back on the host. Mounting
is slightly more practical. We need to get things done, after all.

### How to

To run agentic workflows on an M3 Max 64GB MacBook Pro I run `llama-server`
over [`sandboxed-ai`][1] and the [`aldur-pi`][2] container as follows:

```bash
sandboxed-ai llama-server \
  -hf unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL \
  --spec-type draft-mtp \
  --spec-draft-n-max 3 \
  -ngl 99 -ngld 99 -fa on \
  --jinja \
  --chat-template-file froggeric/Qwen-Fixed-Chat-Templates:chat_template.jinja \
  -c 262144 --parallel 1 \
  -ctk q8_0 -ctv q8_0 \
  -b 4096 -ub 2048 \
  --load-mode mlock \
  --temp 1.0 --top-p 0.95 --top-k 20 --min-p 0 \
  --presence-penalty 0.0 --repeat-penalty 1.0 \
  --reasoning-preserve \
  --perf --log-timestamps -lv 4 \
  --cors-origins localhost \
  --host /tmp/llama/llama.sock \
  2>&1 | tee llama-server.log

# I am also experimenting with fewer checkpoints to reduce memory pressure over long runs.
```

And then `pi` with:

```bash
# Pull the container
container image pull ghcr.io/aldur/aldur-pi:latest

# Run it
env -u SSH_AUTH_SOCK container run -it --rm --network none --no-dns \
    --volume /tmp/llama/llama.sock:/var/host-services/llama.sock \
    --volume "/Work/project:/workspace" \
    --env LLAMA_SOCKET_PATH=/var/host-services/llama.sock \
    ghcr.io/aldur/aldur-pi:latest pi --models 'llama-cpp/*'
```

[0]: https://blog.cryptographyengineering.com/2026/09/30/is-sandboxing-sufficient-to-contain-rogue-agents/
[1]: https://github.com/aldur/sandboxed-ai
[2]: https://github.com/aldur/dotfiles/tree/master/base_hosts/pi-container
[3]: https://pwn.ai/blog/kvmescape
[4]: https://github.com/apple/container/security
