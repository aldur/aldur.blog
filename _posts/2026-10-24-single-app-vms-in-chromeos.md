---
title: A poor man's Qubes OS
excerpt: >
  Single-app VMs in ChromeOS.
related:
  - _posts/2025-10-29-nixos-baguette-images-in-chromeos.md
  - _posts/2026-02-01-impermanent-nixos-vms-in-baguette.md
  - _micros/recovery-signing-node-tailscale-lock.md
---

We have talked about wrapping [AutoFirma into its own
VM](/_micros/a-vm-guest-for-autofirma.md) to prevent it from modifying the
host's keychain and to keep it properly packaged and configured. I liked the
approach and I have recently extended it to a few more things: I now use
WhatsApp and Signal in single-app VMs in ChromeOS. Through this setup I'll be
able to access those services as long as I have one of my hardware keys and a
recent-enough VM backup.

When I started playing around with the idea, I wanted to achieve the equivalent
of passkey-based logins to services and apps that don't natively support
passkeys. Both WhatsApp and Signal, for instance, require scanning a QR code
with the corresponding mobile app to link a desktop client. I wanted something
different: to be able to leave my main devices behind and still be able to
access those services. I wanted to authenticate through a Yubikey and to
securely get online even from a device that had just been wiped.

The solution I came up with builds on ChromeOS VMs and Yubikeys:

- Through [`nixos-crostini`][0], I can easily configure and build multiple
  flavors of NixOS VMs that run on the Chromebook through
  [Baguette](./2025-10-29-nixos-baguette-images-in-chromeos.md).
- Two of the VM flavors that I prepared run a [Firefox browser][2] (for
  WhatsApp Web) and the [Signal desktop app][3]. Each VM builds on a base
  configuration that is moderately hardened and turns off as many services as
  possible. The VM is configured to boot from an immutable filesystem: writes
  go to ephemeral storage, except for state that needs to survive reboots.
- ChromeOS provides the trusted computing base. It can run VMs out of the box
  and provides a generally secure environment in its default configuration. My
  threat model generally trusts ChromeOS; it assumes that an individual VM can
  be compromised, but that an attacker inside the VM wouldn't be able to reach
  the host.
- I configure one VM per service in ChromeOS. I launch each and perform the
  initial configuration by linking its client to the corresponding mobile app.
- Then I export the whole VM disk (usually small, around 1 GB) and I make sure
  that the backup destination isn't shared with any other VM. I use
  [`age-browser`][1] to encrypt it using one or more Yubikeys.
- I then upload the encrypted backup somewhere where I can authenticate with a
  Yubikey passkey (e.g., Google Drive) and destroy the ChromeOS VM and its
  local backups.

When I need one of these services, I authenticate to the drive through the
Yubikey, pull the backup, decrypt it through the browser, and restore the VM. I
recently tested this process while on a business trip and was pretty happy with
it.

A few caveats: I suspect that neither Signal nor WhatsApp would support copies
of the same client running at the same time; I haven't tried that. In addition,
device "links" expire after being inactive for a while. This means that the VM
backup needs to be prepared close enough to when it will be needed. On the
other hand, it means that encrypted backups forgotten on the drive would not be
useful to reconnect to the services after some time; I think that's a nice
thing.

Somewhat cheekily, I think of this setup as a poor man's Qubes OS. The
resulting security posture is weaker, for instance because firewalls run inside
each VM and clipboard and file sharing can weaken isolation. On the other hand,
it relies on mainstream technologies and is convenient to both set up and use.
Chromebooks are also both cheap and easily available: as long as I can access a
Chromebook and one of my Yubikeys, I'll be able to get back online.

[0]: https://github.com/aldur/nixos-crostini
[1]: https://github.com/aldur/age-browser
[2]: https://github.com/aldur/dotfiles/tree/master/base_hosts/browser
[3]: https://github.com/aldur/dotfiles/tree/master/base_hosts/signal
