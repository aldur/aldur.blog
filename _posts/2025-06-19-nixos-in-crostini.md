---
title: "NixOS containers in ChromeOS"
excerpt: >
  How to turn a Chromebook into a secure and productive device through NixOS
  containers and hardware keys.
last_modified_at: 2026-01-18
tags: [ChromeOS]
redirect_from:
  - /nixos-crostini
---

Chromebooks have a reputation of being secure devices:

- _Verified Boot_ ties the integrity of the OS to the underlying hardware.
  Google's marketing material describes it as "a read-only operating system",
  which reduces the chances of malware surviving a reboot.
- _Defense in depth_ makes it hard to compromise the OS in the first place, by
  stacking protections: the Chrome sandbox, the OS userspace,
  the kernel, the firmware, and the hardware.

Because of all this, users can get a _trustworthy_ computing environment by
_powerwashing_ their Chromebook (lingo for a deep but fast wipe) back to a
pristine state. On paper, this is awesome! It makes powerwashed Chromebooks
ideal to handle security-sensitive tasks. The downside is that a powerwashed
device lacks all tools and configuration. It requires going through initial
setup, then logging into online services, configuring tools, and finally
getting to work.

I would like to skip all this and be productive as quickly as possible. Better yet,
I'd like to periodically throw away any persisted state and restart from scratch,
spinning up a new instance every time I need it (e.g., one for personal life,
one for work, or even one for each project).

This post describes my way to achieve that goal through a combination of
hardware security keys and secure, reproducible, throwaway containers.

<!-- prettier-ignore-start -->

- Table of Contents
{:toc}
<!-- prettier-ignore-end -->

## The requirements

I don't need much to be productive: a web browser and a shell. The browser is
my gateway to most apps and services. Even when native or Electron apps are
available, I prefer to run things directly in the browser to leverage its
sandbox, adding another layer to defense in depth. The shell usually provides
all the rest, including an editor and access to other hosts.

A good shell setup should feel like home: for instance, my text editor should
be ready with all the plugins I use; `git` should know who I am and how I
prefer to fetch branches or sign commits. It should be easy to update, audit,
and (re)build the full configuration from scratch. Deploying it to a clean
device should be fast (minutes). Importantly, the environment should _not_
bundle any secret (e.g., passwords or cryptographic keys) or confidential
information, nor should it have access to any long-lived credential.

The lack of secrets and credentials is important for safety:

- If the environment is compromised at rest, there is nothing to exfiltrate.
  Plus, we do not need to worry about delivering it _privately_ to the
  Chromebook, _where_ we store it, _if_ it leaks, and _when_ to dispose it.
- Similarly, an attacker that compromises a running system (e.g., through a
  malicious executable), will not find any long-lived credential to steal.

## The solution

My solution builds on:

1. Hardware keys, holding login credentials and cryptographic keys.
1. NixOS containers, running under Linux on ChromeOS (Crostini).

### Hardware keys

Hardware keys create a physical security boundary for secrets. They ensure that
credentials and cryptographic keys never leave the hardware device and are
never exposed to the host.

Through hardware keys I:

1. Login to online services (thanks to WebAuthn and passkeys).
2. Prove second factors ("something I have").
3. Authenticate to other hosts (through SSH) and sign messages.

A good number of online services allow passwordless login through passkeys.
There is no need to type (or remember) my username and password. I visit their
website through Chrome, unlock the hardware key through its PIN, and login.

In some cases, a hardware key can only be used as a second factor. When that
happens, I use it to decrypt the password from a vault (e.g. using
[`passage`][0] in the shell, or
authenticating to a password manager with a passkey). As more services embrace
passkeys, the need for passwords will hopefully become less frequent.

Lastly, the hardware key holds SSH keys used both for authentication (`ssh`)
and signing (e.g., `git commit`) from the shell.

### NixOS containers

<div class="hint" markdown="1">

  If you are looking for containerless VMs,
  [this post implements the same approach for `baguette`](2025-10-29-nixos-baguette-images-in-chromeos.md).

</div>

One of the killer features of Chromebooks is that they have good support for
running Linux without compromising on security. Technically, a system called
Crostini runs a Linux VM (booting a hardened kernel), which in turn runs `lxc`
containers. The default container is Debian.

What makes Crostini great as opposed to SSH into a remote system is that it has
first-class integration with ChromeOS. You can run Linux GUI apps and they will
show up alongside all other Chrome apps; you can open a URL in Chrome from the
Linux container; you can share the clipboard between Linux and ChromeOS;
non-priveleged ports on the container are even forwarded from `localhost` on
the host.

The default Debian container ships a few services that make that magic
happen. Here are the most useful two:

- `garcon` provides bidirectional communication between ChromeOS and the
  container. The Terminal app uses it to connect to the container console, the
  Files app to browse container files, and Chrome to open URLs from the
  container.
- `sommelier` implements clipboard sharing and lets the container launch GUI
  applications in ChromeOS.

The obvious downside of the Debian container is that it is "vanilla" and
requires customization before feeling like home. That's where NixOS makes a
difference: it makes it easy to build a container image that includes all
required tools (think `git`, `ssh`, `nvim`, even the AWS CLI) and their
configuration (`.dotfiles`, profiles, etc.).

To get NixOS running under Crostini:

1. I prepared a custom NixOS image that included my dotfiles and the tools I
   usually need.
2. I included and configured `garcon` and `sommelier` to integrate nicely
   with ChromeOS.
3. I figured out how to get the image on the Chromebook and run it.

#### How-to: Preparing the image

Nix makes it relatively easy to build a custom `lxc` image. But Nix can also be
a pretty deep rabbit hole, which would require more than one blog post to
explain. Instead, I have prepared a simple {% include github_link.html
url="https://github.com/aldur/nixos-crostini" text="quick start" %} that
includes a sample configuration and can be useful to both new Nix users and
veterans to get up and running.

The repository also includes the {% include github_link.html
url="https://github.com/aldur/nixos-crostini/blob/main/common.nix" text="magic glue" %}
that makes it work by running `garcon` and `sommelier` through
`systemd`. The ChromeOS source code and the `cros-container-guest-tools-git`
[AUR package][11] were invaluable in making this happen.

After you import this module in your configuration and build the image, the
next step is to get it on your Chromebook. There are
[a few ways](../_micros/more-ways-to-bootstrap-nixos-containers.md) to do this,
including building it in the default Debian container, copying it over through
a USB stick, and uploading it to Drive.

If you have another NixOS instance handy, you can push it to an [LXD image
server][12]
[behind Tailscale](../_micros/more-ways-to-bootstrap-nixos-containers.md#from-an-lxd-image-server-behind-tailscale).
To do that, first enable `lxd`:

```nix
virtualisation.lxd.enable = true;
```

Then, enable the image server as follows:

```bash
# `lxd` can't be configured declaratively in NixOS, go figure!
sudo lxc config set core.https_address :8443
```

You can now import the image with and get it ready for the Chromebook.

```bash
# Replace `lxc-metadata` and `lxc` with the directories where you built the metadata and the RootFS.
lxc image import --public --alias lxc-nixos ${lxc-metadata}/tarball/*.tar.xz ${lxc}/tarball/*.tar.xz
```

#### How-to: Deploying the image

If you haven't already, [enable Linux on ChromeOS][13]. When asked,
choose the same username you will use within the container. I usually allocate 32GB
of storage.

Now open `crosh` (<kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>T</kbd>), then:

```sh
vmc destroy termina  # Not strictly required, but better start clean.
vmc start termina
```

If you are using an image server behind Tailscale, install the Tailscale app
from the Play Store and use the hardware key to authenticate. Otherwise, follow
one of the approaches described
[here to deploy the image to the Chromebook](../_micros/more-ways-to-bootstrap-nixos-containers.md).

From inside `termina`:

```bash
# Assuming `tropic` is the hostname of the `lxd` server you have configured before.
lxc remote add tropic https://tropic:8443 --public

# Ensure you can see the image listed.
lxc image list tropic:

# Download the image and setup the container.
# NOTE: Transfer speed into `termina` depends on the Chromebook.
# I try to keep the image small so that this is fast.
lxc init tropic:lxc-nixos lxc-nixos --config security.nesting=true
```

<div class="warning" markdown="1">

I have sometimes seen `--config security.privileged=true` recommended as well.

Don't use it! If you do, you will spend a couple hours (as I did) trying
to figure out why USB devices correctly show up in `lsusb` but then error with
"permission denied" when you try accessing them. In my experience, there is
no need for that flag.

The `security.nesting=true`, instead, is required to run `nix` in the
container. It is part of the default configuration that Crostini uses to init
containers, and it is the right choice.

</div>

<div class="hint" markdown="1">

At this point, if you want, you can skip directly to [launch the container from
"Terminal"](#how-to-launch-the-container-from-terminal).

Read on, instead, if you'd like to understand how this works under the hood.

</div>

You can now start the container and, after a few seconds, it should get an IP
through DHCP:

```bash
lxc start lxc-nixos

# Peek at the console logs, if you want
lxc console --show-log lxc-nixos

# Wait until `lxc list` shows an IP.
lxc list
```

At this point you can `exec` into the container and play around with it:

```bash
lxc exec lxc-nixos bash
```

We are not done yet, though! First, we don't need to be logging in as root.
Second, `garcon` will not work yet, because it will be missing a required file:
`/dev/.container_token`. As far as I can tell, to get `.container_token` we
need to start the container from `crosh`. So:

```bash
# From Termina (ctrl-d if you are still in `lxc-nixos`)
lxc stop --force lxc-nixos

# From crosh (ctrl-d from `termina`)
# This will ensure `/dev/.container_token` exists within the container
vmc container termina lxc-nixos
```

This command will likely error out, complaining that the container cannot be
found. Fear not! The container has started in the background. Once it gets an
IP, you'll get a shell by re-running the same command. You should then be
able to check that `garcon` and `sommelier` are correctly running.

```bash
vmc container termina lxc-nixos

# Now, in `lxc-nixos`
systemctl --user status garcon.service
systemctl --user status sommelier@0.service
systemctl --user status sommelier-x@0.service
```

We can also make a couple of tests:

```bash
# This should populate your ChromeOS clipboard (you can check it with launcher-v or by pasting somewhere).
# Under the hood, it uses `sommelier` through the Wayland protocol.
echo "Clipboard works!" | wl-copy

# This should have a pair of goggly eyes pop on your screen and is testing X proxying through `sommelier-x`
nix run nixpkgs#xorg.xeyes
```

#### How-to: Launch the container from "Terminal"

<div class="admonition" markdown="1">

ChromeOS 141 unfortunately deprecates the `#crostini-multi-container` flag that
[allowed to manage multiple containers through the UI](../_micros/multiple-crostini-containers.md).

Integrating `lxc-nixos` with "Terminal" now requires replacing the original
Debian container.

</div>

To launch the `lxc-nixos` from "Terminal", rename it to `penguin` as follows:

```bash
lxc stop --force penguin
lxc stop --force lxc-nixos
# Rename the original "penguin" to "debian"
lxc rename penguin debian
lxc rename lxc-nixos penguin
lxc start penguin
```

From now on, use `penguin` instead of `lxc-nixos` in all `lxc`/`vmc`
invocations.

#### How-to: USB forwarding

In order to use hardware keys within the container, you will also need to set up
USB forwarding.

Every time you plug a USB device in, ChromeOS should prompt you whether you
want to connect it to Android or Linux. Connecting it to Linux this way has
never worked for me, possibly because this method attach the device to the VM,
but not to the container. Instead, I just use the CLI.

Insert the device and then navigate to `chrome://usb-internals`. In the
`devices` tab, note the Bus number and Port number of your device.
`dmesg` in `crosh` will provide the same information, if you prefer.

Now open a new `crosh` shell and attach the USB to the container:

```bash
# Replace <bus> and <port> with the Bus and Port number from above.
vmc usb-attach termina <bus>:<port> lxc-nixos
```

<div class="warning" markdown="1">

The container name at the end of the `usb-attach` command is **fundamental**!
Without it, the security key will show up in the container but you will not be
able to use it.

<details markdown=1>
  <summary markdown=span>Under the hood</summary>
It ensures that `lxc` will add the following to the container configuration:

```
/dev/bus/usb/001/011:
  major: "189"
  minor: "10"
  mode: "0666"
  path: /dev/bus/usb/001/011
  type: unix-char
```

</details>

</div>

<div class="seealso" markdown="1">

The [Smart Card Connector][14]
app can hold a lock on the hardware key, making the above command fail. I
recommend disabling it and only enable it when needed (e.g., for [SSH access
through Terminal](#how-to-ssh-into-the-container)).

<details markdown=1> <summary markdown=span>Symptoms</summary> If Smart Card
Connector is holding a lock on the device, the `usb-attach` command below might
fail and looking at `/var/log/messages` would show this message: `Verdict for
/dev/bus/usb/002/004: DENY`.
</details>

</div>

In the container, `lsusb` should show the device as ready for use. If you
[configured it for SSH authentication](2025-06-26-yubikey-agent.md), `ssh-add
-L` should show your keys.

If `lsusb` detects the device, but the hardware key does not work when queried
for keys (e.g., with `ssh-add -L`), restart the `pcscd` service and try again.

#### How-to: SSH into the container

If you your container ships an SSH server, you can connect to it through the
built-in Terminal application. Use the container's IP (`ip addr show`) or the
domain `lxc-nixos.termina.linux.test` (this is hit or miss, sometimes
`cicerone` will not correctly detect the IP and the hostname won't resolve).

[Getting SSH from ChromeOS to work](../_micros/ssh-from-chromeos-terminal.md)
required me to jump through so many hoops that the effort is not worth the
result. I do not recommend it, but I have left this note in case it is useful
to you.

<div class="admonition" markdown="1">

Remember! The [Smart Card Connector][14] app required for SSH through ChromeOS
[conflicts with USB forwarding](#how-to-usb-forwarding). Disable it when not
using it.

</div>

#### How-to: Root login

I either [SSH as `root` or use `lxc exec`](2025-06-27-yubikey-root-login.md) to
escalate privileges easily and safely.

## Conclusion

Software-wise, my `crostini.nix` module handles the heavy lifting and gets the
things I need to work. I haven't tested hardware acceleration, audio, and
there's probably a few more things that do not work yet (when compared to
Debian). I can always add those things when the need arises. Clipboard sharing
between Chrome and Crostini is probably my most used feature, in addition to
opening URLs in Chrome from the container.

Hardware-wise, Chromebooks are great "couch-computing" or travel devices. They
are underpowered with respect to other machines (e.g., an M4 MacBook). But they
are lighter and cheaper, and their battery is OK considering they are "Linux"
devices (ARM Chromebooks can easily last 12 hours on battery). I wish the
display was a bit brighter, especially under direct sunlight.

Overall, after using this setup for a few weeks I am satisfied with it -- I
even wrote this blog post on a Chromebook! It does what I need, strikes a good
security posture, and I like being able to go from _zero_ to _productive_ in a
couple minutes. Once the container boots, I immediately feel at home. I can
quickly get ahead and write my thoughts, hack on a new project, or put off the
occasional fire at work. Having a full system bottled up and ready to deploy
also gives me confidence that I could recover quickly in case of disaster
(fire, natural disaster, theft, etc.), removing any specific machine as a
single point of failure. Lastly, this setup is trivial to deploy to a different
system: I have had some fun playing with AI agents in a `qemu` VM built using
the same tools.

Thanks for reading, and 'til next time! 👋

<div class="hint" markdown="1">

  The ChromiumOS team is experimenting with a way (codename `baguette`) to run
  containerless VM images.
  [This post describes how to use the approach described here to build NixOS `baguette` images](2025-10-29-nixos-baguette-images-in-chromeos.md).
  Give it a try and let me know how it works for you!

</div>

## References

- [ChromeOS Security Whitepaper][1]
- [Crostini Developer Guide][2]
- [Running Custom Containers Under ChromeOS][3]
- [Port forwarding and tunneling in ChromeOS][4]
- [Crosh -- The ChromiumOS shell][5]
- [ArchLinux wiki: ChromeOS Devices][6]
- [NixOS wiki: Installing Nix on Crostini][7]
- [Chrome internals: DNS (copy/paste to your browser URL bar)][8]
- [Logging on ChromeOS][9]
- [`/var/log/messages` from Chrome][10]

[0]: https://github.com/FiloSottile/passage
[1]: https://www.chromium.org/chromium-os/developer-library/reference/security/security-whitepaper/#hardware-root-of-trust-and-verified-boot.md
[2]: https://www.chromium.org/chromium-os/developer-library/guides/containers/crostini-developer-guide/
[3]: https://www.chromium.org/chromium-os/developer-library/guides/containers/containers-and-vms/
[4]: https://www.chromium.org/chromium-os/developer-library/reference/security/port-forwarding/
[5]: https://www.chromium.org/chromium-os/developer-library/reference/device/crosh/
[6]: https://wiki.archlinux.org/title/Chrome_OS_devices/Crostini
[7]: https://wiki.nixos.org/wiki/Installing_Nix_on_Crostini
[8]: chrome://net-internals/#dns
[9]: https://www.chromium.org/chromium-os/developer-library/reference/logging/logging/
[10]: file:///var/log/messages
[11]: https://aur.archlinux.org/packages/cros-container-guest-tools-git
[12]: https://ubuntu.com/tutorials/create-custom-lxd-images#6-making-images-public
[13]: https://support.google.com/chromebook/answer/9145439?hl=en
[14]: https://chromewebstore.google.com/detail/smart-card-connector/khpfeaanjngmcnplbdlpegiifgpfgdco
