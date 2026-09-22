---
title: 'NixOS for Apple container'
last_modified_at: 2026-06-18
excerpt: >
  Building NixOS images that run both as containers and VMs on macOS.
---

I have written at length about containers and VMs on this blog: I use them
daily to segregate work, contain rogue AI agents, and defend against
supply-chain attacks. To build a good developer experience, I package
everything with NixOS.

A couple of days ago Apple released `v1.0.0` of [`container`][1], a tool to run
Linux containers on macOS. I decided to give it a try and compare it against
QEMU (battle-tested, but with a large attack surface).

Under the hood, `container` consumes standard OCI images and runs them either:

1. as an _ephemeral_ container (with `container run`), where each container
   gets its own VM;
1. as a _persistent_ VM (with `container machine create`, then `... run`).

The VM automatically forwards your SSH socket and mounts your home directory
read/write. Unset `SSH_AUTH_SOCK` and add `--home-mount none` to prevent both.

NixOS doesn't use [FHS][2] and containers don't run `systemd`. So I wrote a
small NixOS module that ensures a smooth boot. It loads the Nix database and
bundles the TLS roots, provides the filesystem shims and the UID that Apple's
`init` expects, sets up the session environment, and waits for the rest of the
system (e.g., `home-manager`) to come up. Figuring out all this took Claude a
few round trips, with me supervising to keep things minimal, DRY, and elegant.

The result is [this Nix flake][0]. It includes:

- a NixOS module (use it to build your own NixOS image),
- a minimal NixOS image,
- and a full image of my configuration.

The same NixOS image can run both as a container and as a persistent VM. To
give it a try, install [`container`][3] and then run:

```bash
$ container run -it --rm ghcr.io/aldur/nixos:latest

[nixos@nixos:~]$ nix shell nixpkgs#cowsay
[nixos@nixos:~]$ cowsay "Hello, world!"
 _______________
< Hello, world! >
 ---------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||

[nixos@nixos:~]$
```

Or, for the VM:

```bash
$ container machine create ghcr.io/aldur/nixos:latest --home-mount none
nixos-latest
$ container machine run -n nixos-latest

[nixos@nixos:/home/aldur]$ id
uid=501(nixos) gid=20(lp) groups=20(lp)

# If you are confused about `/home/aldur`,
# container VMs derive `cwd`, `id` and `guid` from your macOS user.
```

#### Careful with those backups

A few days after writing this post, I discovered that
[`container` bloats Time Machine backups](../_micros/psa-apple-container-bloats-time-machine-backups.md).
Prevent that by excluding its state directory with:

```bash
tmutil addexclusion ~/Library/Application\ Support/com.apple.container
```

[0]: https://github.com/aldur/dotfiles/tree/master/base_hosts/apple-container
[1]: https://github.com/apple/container
[2]: https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard
[3]: https://github.com/apple/container/releases/tag/1.0.0
