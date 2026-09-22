---
title: 'Two SSH keys on a Yubikey'
date: 2025-06-26 11:17:00 +0200
excerpt: >
  I use a single Yubikey and two SSH keys to authenticate to remote hosts and sign commits.
tags: [ChromeOS]
---

With [NixOS containers in ChromeOS](2025-06-19-nixos-in-crostini.md), I use an
SSH key in a Yubikey to authenticate to remote hosts and keep the key separated
from the container.

Creating keys on the Yubikey and ensuring good UX while using them can be
tricky, but [`yubikey-agent`][0] makes it seamless. There's a catch though! It
supports one SSH key only, while I'd like to use two:

1. One to authenticate (e.g., to GitHub).
2. The other to [sign `git` commits][sign_commits].

This way, I can implement separation of duties and can
"decommission"[^decommission] each key independently.

A few PRs in the `yubikey-agent` repository add support for multiple keys and
even different policies (touch, PIN). Most try to develop a generic approach,
while I only need to support two keys. So, I decided to scratch my own itch and
implement a solution.

Luckily, the agent is written in Go, is easy to understand. The
[`piv-go`][1] does the heavy lifting. Under the
hood:

- It asks the Yubikey to generate an elliptic curve (ECC256) key pair in the
PIV Authentication slot.
- Then it creates a self-signed X509 certificate to wrap the public key and
make it available to clients (our SSH agent) through the PKCS#11 interface.

[This Yubikey tutorial][2] describes roughly the same process, but I find the
Go code easier to read and more precise. In addition, the setup guides the user
through the PIN/PUK setup and removes the need for a management key by
delegating its control to the PIN/PUK.

To support two keys, I decided to go the simplest approach and make the minimum
set of changes to the code to generate a new key (during the setup phase) and
then serve it through the SSH agent. I initially considered generating the key
through the CLI, but the delegation of the management key made it hard to do,
so I just went with code for the setup as well. By poking around the `piv-go`
code and the PIV standard, I decided to use slot `9c`, which is used for
Signature (the Yubikey docs even mention using it for `git commit`).

The result is in {% include github_link.html
url="https://github.com/aldur/yubikey-agent" text="my fork of the project" %}.
I intentionally kept the code as simple as possible, so that it is easy to
maintain and follow upstream (in case I need to). If you want to try it out,
setup the Yubikey as usual and then run `yubikey-agent -setup-sign` to generate
the additional key. When running the agent, it will gracefully try loading both
keys and ignore the one for Signatures if it cannot be found.

I have also ensured that the ordering of the keys doesn't change and have
configured my `git` client to sign with the _second_ key returned by the agent.
This is convenient to use and matches my configuration on other hosts.

Here is the result:

```bash
[I] aldur@lxc-nixos ~> ssh-add -L
ecdsa-sha2-nistp256 AAAAE2V...iUkW4JQUDA= YubiKey #25972834 PIV Slot 9a
ecdsa-sha2-nistp256 AAAAE2V...pKYi/Zh/HA= YubiKey #25972834 PIV Slot 9c
```

To deploy my changes, I wrote a small Nix overlay that applies my patch:

```nix
(final: prev: {
  yubikey-agent = (
    prev.yubikey-agent.overrideAttrs (old: {
      # Used a patch instead of overriding the source so that it will keep
      # working (or explicitly break) on upstream updates.
      patches = (old.patches or [ ]) ++ [
        (prev.fetchurl {
          url = "https://github.com/aldur/yubikey-agent/commit/f7a6769fd832a867e62228c8ddb0133174db64bf.patch";
          hash = "sha256-swQb3N89yAJSQ4pkUq2DDKvEFBlzhr/tbNMdC2p60VE=";
        })
      ];
    })
  );
})
```

[^decommission]: Ideally I'd want to revoke keys, but there is no built-in way
    to do it for SSH (that I am aware of). The PIV standard relies on
    certificates, so there might be a way to revoke them -- but then, consumers
    would need to check a revocation list, and I don't think they do. GPG keys
    can be revoked, but come with other downsides.

[sign_commits]: https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification#ssh-commit-signature-verification

[0]: https://github.com/FiloSottile/yubikey-agent
[1]: https://github.com/go-piv/piv-go
[2]: https://developers.yubico.com/PIV/Guides/PIV_Walk-Through.html
