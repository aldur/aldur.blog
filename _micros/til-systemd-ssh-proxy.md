---
title: 'TIL: systemd-ssh-proxy'
date: 2026-10-17
related: _posts/2025-06-27-yubikey-root-login.md
---

I use `ssh` as a [poor man's
`sudo`](../_posts/2025-06-27-yubikey-root-login.md#take-4-good-old-ssh) that
relies on a cryptographic key instead of a password. To do that, I typically
allow `root` login only through `localhost`, to reduce attack surface. You
first login as a local user, and then use `ssh root@localhost` to escalate
privileges. This required configuring the SSH daemon in a very specific way.

Recently, I discovered [`systemd-ssh-proxy`][0], a small plugin for the SSH
daemon that:

1. Enables `ssh root@.host`. Under the hood, this relies on UNIX or VSOCK
   sockets and doesn't involve any networking.
1. Is enabled by default on NixOS.

I have now [simplified][1] my SSH configuration. Using defaults where possible
is better and less error-prone.

[0]: https://www.freedesktop.org/software/systemd/man/latest/systemd-ssh-proxy.html?__goaway_challenge=meta-refresh&__goaway_id=55b9137a70ed6a75428360b6c92666f9
[1]: https://github.com/aldur/dotfiles/commit/3b019cce9ee7ce4d36632dee8c2329f812306565
