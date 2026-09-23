---
title: 'Tailscale and ChromeOS Baguette'
date: 2026-03-22
tags: [ChromeOS]
---

When running [NixOS in ChromeOS](../_tag_indexes/ChromeOS.md), I use Tailscale
to access a few remote hosts.

Although Tailscale can run within the VM itself, I prefer to run its Android
app in ChromeOS. This way, the VM never sees the raw Tailscale credentials and,
if running multiple VMs, they can all share network access.

Under the hood, all VM traffic already flows through the host, enabling
Tailscale routing. In addition, the [NixOS Baguette image][0] delegates DNS
resolution to the host, as follows:

```bash
ln -sf /run/resolv.conf /etc/resolv.conf
```

`maitred` [takes care][1] of populating the `/run/resolv.conf` file as the host's
network configuration changes:

```bash
Mar 17 10:26:43 baguette-nixos maitred[412]: Received request to update VM resolv.conf
```

Activating and de-activating Tailscale correctly updates the `resolv.conf`
file. With Tailscale enabled, it will look as follows:

```bash
nameserver 100.100.100.100
search [redacted].ts.net
```

The `search` configuration allows using `ping <hostname>` or `ssh <hostname>`
from the VM without specifying the Tailnet FQDN (something that wasn't working
in `crostini`). Queries _outside_ the Tailnet go through the host's DNS
configuration.

[0]: https://github.com/aldur/nixos-crostini
[1]: https://chromium.googlesource.com/chromiumos/platform2/+/c4c2468e01f6b37c97d842c9981b1bafb71d751b/vm_tools/maitred/service_impl.cc#168
