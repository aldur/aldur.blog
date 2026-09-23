---
title: 'Unresponsive Claude'
date: 2025-10-02
last_modified_at: 2025-10-03
---

I recently spent a couple of hours debugging why `claude-code` was entirely
unresponsive when launched within a QEMU VM: it wouldn't register any keyboard
input or show any sign of interactivity. I am sharing the result here so that,
hopefully, I can save your time, dear reader.

<div class="hint" markdown="1">
tl;dr: [This `resize` script][smoking_gun]
from the `vm-nogui` NixOS generator was wreaking havoc.
</div>

For a bit of context: I only run `claude-code` within VMs or containers. On
this occasion, it was running inside a QEMU VM built through
[nixos-generators](https://github.com/nix-community/nixos-generators) with the
`vm-nogui` format. The unresponsiveness was only manifesting there, not within
[LXC containers](../_posts/2025-06-19-nixos-in-crostini.md).

Running Claude with `--debug` wasn't very helpful but sometimes would show some
error logs about a resize script and the following error:

```bash
'standard input': Inappropriate ioctl for device
```

Through a bit of trial and error, I noticed that `/etc/profile` was sourcing
[this script][smoking_gun], which should apparently resize the serial console.
The trouble with it is that it will try to run even for non-interactive
sessions, resulting in the above error and in Claude freezing completely.

I {% include github_link.html
url="https://github.com/aldur/dotfiles/commit/8b2fca2fd1ca27914e5b369d4143411d55518bde"
text="solved the issue" %} by leaving the `resize` script available to the
system (in case I need to run it manually) but removing the automation for it
in `/etc/profile`:

```nix
# Overwrite `loginShellInit` since `resize` does more harm than good
# https://github.com/nix-community/nixos-generators/blob/032decf9db65efed428afd2fa39d80f7089085eb/formats/vm-nogui.nix#L20C3-L20C29
environment.loginShellInit = lib.mkForce "";
```

I also opened an
[issue](https://github.com/nix-community/nixos-generators/issues/447) upstream
in case someone else has the same problem.

[smoking_gun]: https://github.com/nix-community/nixos-generators/blob/fb30cf1cbebe3f5100dbd605138b2eec44ad217f/formats/vm-nogui.nix#L2-L11
