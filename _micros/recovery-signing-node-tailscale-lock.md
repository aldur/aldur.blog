---
title: 'A recovery signing node for Tailscale Lock'
date: 2026-10-24
---

A quick follow-up to today's [poor man's
QubeOS](/_posts/2026-10-24-single-app-vms-in-chromeos.md).

I am using the same approach to also make a Tailscale Lock signing node
available from a backup encrypted using a YubiKey. [Tailscale Lock][0]
requires new Tailscale nodes to be signed by an existing authorized signing
node.

To be able to recover access to my tailnet without any usual trusted device, I:

1. set up an empty NixOS VM in Baguette,
1. configured `tailscale`,
1. authorized it through an existing Tailscale signing device,
1. promoted it to be itself a signing device,
1. then backed up its state, encrypted the backup through a YubiKey, and
   uploaded it to a cloud drive.

From Tailscale's console, I then disabled key expiration for the new device.
Lastly, I destroyed the VM.

The device now sits disconnected in my Tailscale dashboard as
`tailnet-recovery`, as a reminder of the recovery setup.

[0]: https://tailscale.com/docs/features/tailnet-lock
