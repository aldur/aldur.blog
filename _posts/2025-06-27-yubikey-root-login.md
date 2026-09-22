---
title: 'Root login in NixOS containers'
date: 2025-06-29 17:25:00 +0200
excerpt: >
  Finding a secure and usable privilege escalation method for NixOS containers.
tags: [ChromeOS]
---

When working in
[NixOS containers under ChromeOS](2025-06-19-nixos-in-crostini.md), the
container users `root` and `aldur` have no password. This is very convenient,
as it avoids managing secrets in the NixOS configuration. However, it makes
securely escalating privileges tricky: both `sudo` and `su` ask for the user
password, which we can't provide.

This post details my journey to find a secure and usable privilege escalation
method for NixOS containers.

### Take 0: the baseline

When the container runs via `lxc` within the `termina` VM in ChromeOS, we
can spawn a root shell directly from Crosh:

```bash
# Replace with `bash` if that's what you are using.
lxc exec <container-name> fish
```

This works well and requires no extra configuration. However, it's
inconvenient. It requires ChromeOS, and relies on access to the host VM. If
[ChromeOS
Baguette](https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/vm_tools/baguette_image/)
graduates to production, this approach will not work anymore.

### Take 1: _insecure_, passwordless `sudo`

Enabling passwordless `sudo` for the users in the `wheel` group is temptingly
simple. NixOS makes it easy by setting `security.sudo.wheelNeedsPassword =
false`. The result, however, also makes it easy for an attacker to escalate
privileges and is essentially equivalent to being `root` all the time. Not
ideal.

### Take 2: _unsupported_, `pam-u2f`

Since I [already use a Yubikey](2025-06-26-yubikey-agent.md) to authenticate
through SSH, sign commits, and even decrypt vaults, I considered using it for
privilege escalation as well. This approach would maintain a separation of
concerns between the users while providing a reasonable security
posture[^shared_kernel].

The [`pam-u2f`](https://github.com/Yubico/pam-u2f) module is the modern way to
go for this. However, FIDO2 doesn't currently work under Crostini, due to
[missing raw USB HID device
access](https://github.com/Yubico/yubikey-manager/issues/464). The
corresponding kernel changes have been
[merged](https://issuetracker.google.com/issues/215265422?pli=1) upstream last
year, so hopefully this will be fixed soon.

### Take 3: _insecure_, `yubico-pam`

Yubico originally maintained the aptly named
[`yubico-pam`](https://github.com/Yubico/yubico-pam/tree/master) module, which
relies on HMAC-SHA1 Challenge-Response. 

This module is now deprecated, but I managed to get it working by digging
through the [old
docs](https://github.com/Yubico/yubico-pam/blob/master/doc/Authentication_Using_Challenge-Response.adoc).

<details markdown=1>
  <summary markdown=span>Setting up `yubico-pam` in NixOS</summary>

First, setup the Yubikey:

```bash
# Configure the Yubikey OTP Slot 2 for Challenge-Response
nix shell nixpkgs#yubikey-personalization
ykpersonalize -2 -ochal-resp -ochal-hmac -ohmac-lt64 -oserial-api-visible

# Now generate the challenge/response file
nix shell nixpkgs#yubikey-pam
ykpamcfg -2 -v -t /tmp

# This will create a file named <user>-<yubikey-serial>, e.g. aldur-324448.
# Copy its contents.
```

Next, configure `yubico-pam` in NixOS so that it relies on local
challenge/response (instead of cloud-based) and so that the Yubikey replaces
the password:

```nix
systemd.tmpfiles.rules = let
  rootChallenge =
    "v2:6fb040e2db2e5b881884adc0e60f8309f4929232e266344a790e7dd2f66b0b633d9e100cd6178258de0ad3cfb23d6a16536652d995f6238c2adc5c39880afe:a6055bd637546b2a87282ef3dc9023d5c99a637c:b21fbb0c37b317d14291db0cad4ea1e9f0a3f2687fea06b87d57983c229f0646:10000:2";
in [
  "d /var/yubico 0700 root root - -"
  "f /var/yubico/root-25972834 0600 root root - ${rootChallenge}"
];

# NOTE: By default this enables yubico auth for _all_ PAM services.
security.pam.yubico = {
  mode = "challenge-response";
  enable = true;
  control = "sufficient";
  challengeResponsePath = "/var/yubico";
};
```

Lastly, rebuild your system configuration, plug-in the Yubikey, attach it to
the Termina VM, and try using `su` or `sudo` to escalate privileges.

</details><br/>

Unlike `pam-u2f`, this module does _not_ require touching the Yubikey when
authenticating. For this reason, this method is _almost_ as weak as
passwordless `sudo`. An attacker can easily escalate privileges if the Yubikey
is plugged-in, while the user will have a hard time noticing it.

### Take 4: good old SSH

Since the container already ships with OpenSSH enabled, why not reuse it
to get a `root` shell?

We have already done the heavy lifting to use SSH identities from hardware
keys to remote hosts. We can simply authorize those same identities to sign-in as
`root` locally:

```nix
users.users.root = {
  openssh.authorizedKeys.keys = (import ../authorized_keys.nix);
};

services.openssh.settings.AllowUsers = [ "root" ];
```

This approach strikes an good trade-off. OpenSSH is battle-tested and would be
running anyway, adding no new services. While I typically disable SSH for
`root` to reduce attack surface, the container runs in a namespaced network
connected only to the host, which mitigates the risk. 

The main downside is usability. This approach leaves out `sudo`; the `root`
shell comes with its own profile and environmental variables, which reduces
ergonomics with respect to a fully configured user shell.

### Bonus take: `ssh-agent`

If you miss `sudo`, we can get it working through [another PAM
module](https://github.com/jbeverly/pam_ssh_agent_auth) that authenticates
through an SSH agent (and, by extension, hardware-backed SSH keys).

Enabling it in NixOS is easy as usual:

```nix
security.pam.sshAgentAuth.enable = true
```

By default, the module will read keys from `/etc/ssh/authorized_keys.d/%u`
(where `%u` is the username authenticating), which is exactly where
`user.users.<name>.openssh.authorizedKeys.keys` stores keys.

This setup leverages the existing `SSH_AUTH_SOCK` and, for this, is also
compatible with
[`yubikey-agent`](https://github.com/FiloSottile/yubikey-agent). running `sudo
echo "Hello world!"` will prompt for your Yubikey PIN (just like SSH) and
elevate your permissions.

The trade-off here is harder to evaluate: it brings a usability win with
seamless `sudo`; but it also adds the surface of another PAM module. The module
code is written in C, its last commit was a few years ago, and it is [not
hard](https://github.com/NixOS/nixpkgs/issues/31611) to configure it so that
public keys are user-writable and render the system insecure. Use it with care!

#### Footnotes

[^shared_kernel]: Yes, I am aware of the perils of a shared kernel and its exploits.

