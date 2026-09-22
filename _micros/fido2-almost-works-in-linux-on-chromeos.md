---
title: 'FIDO2 almost works in Linux on ChromeOS'
date: 2025-07-30
tags: [ChromeOS]
---

ChromeOS can run Linux containers on a virtual machine, in a system called
[Crostini][0]. I have recently gone through
[a few rabbit holes about it](../_tag_indexes/ChromeOS.md).

#### USB security keys

The VM and the containers add a layer of separation from the main operating
system. That's great from a security point of view! But it limits what one can
do inside the Linux environment. Specifically,
[USB devices need to be forwarded](../_posts/2025-06-19-nixos-in-crostini.md#how-to-usb-forwarding)
to the VM (first) and to the container (next). And, because the VM runs a
hardened kernel, not all USB devices will work correctly.

After some trial and error, I
[managed](../_posts/2025-06-19-nixos-in-crostini.md#how-to-usb-forwarding) to
get Yubikeys to work reliably in Linux for SSH for authentication and
signatures. Under the hood, the
[`yubikey-agent`](../_posts/2025-06-26-yubikey-agent.md) and the `pcscd (8)`
Linux processes communicate with the Yubikey through its [PIV
interface](https://developers.yubico.com/yubico-piv-tool/YubiKey_PIV_introduction.html).
This does the job well-enough, but has two downsides:

1. `pcscd` and `yubikey-agent` add moving parts. They could break, misbehave,
   or have vulnerabilities.
1. The Linux VM/container acquire an exclusive lock on the Yubikey, which
   cannot be used from ChromeOS until detached (e.g., as a passkey).

#### FIDO2

Can we do better?

In 2020, `openssh` rolled out support for FIDO2 security keys ([Yubikeys can
do that too](https://developers.yubico.com/SSH/Securing_SSH_with_FIDO2.html)).
FIDO2 is the same technology powering WebAuthn and passkeys. It requires that
the cryptographic keys used for authentication (in this case) never leave the
device. They also require the hardware to validate _user presence_ (by touching
the Yubikey) before producing any signature. This ensures that malware will not
be able to either _exfiltrate_ the secret or use it without the user knowing.

Under the hood, FIDO2 relies on [raw USB HID
access](https://docs.kernel.org/hid/hidraw.html), typically exposed by the
Linux kernel at `/dev/hidraw*`. The `vmc usb-attach` command that forwards USB
devices from the Chromebook to the container does not forward the raw HID and,
for this, the container will not be able to interact with the Yubikey using
FIDO2.

The other day, while poking around the `vmc` command used to setup Linux on
ChromeOS, I noticed that it has special support for "security keys":

```bash
crosh> vmc
USAGE: vmc [
  # ...
  |  key-attach <vm name> <hidraw path>
]
```

Maybe, that would enable FIDO2 keys to work in containers? I decided to find that out.

#### Raw HID passthrough

After plugging the Yubikey, `dmesg` in Crosh tells us that it exposes two HID interfaces:

```txt
[ 4058.807454] usb 2-1.1: new full-speed USB device number 5 using xhci-mtk
[ 4058.897447] usb 2-1.1: New USB device found, idVendor=1050, idProduct=0407, bcdDevice= 5.43
[ 4058.897479] usb 2-1.1: New USB device strings: Mfr=1, Product=2, SerialNumber=0
[ 4058.897493] usb 2-1.1: Product: YubiKey OTP+FIDO+CCID
[ 4058.897504] usb 2-1.1: Manufacturer: Yubico
[ 4058.900525] input: Yubico YubiKey OTP+FIDO+CCID as /devices/platform/soc/16700000.usb/usb2/2-1/2-1.1/2-1.1:1.0/0003:1050:0407.0006/input/input12
[ 4058.953054] hid-generic 0003:1050:0407.0006: input,hidraw3: USB HID v1.10 Keyboard [Yubico YubiKey OTP+FIDO+CCID] on usb-16700000.usb-1.1/input0
[ 4058.954201] hid-generic 0003:1050:0407.0007: hiddev96,hidraw4: USB HID v1.10 Device [Yubico YubiKey OTP+FIDO+CCID] on usb-16700000.usb-1.1/input1
```

We care about the second one, in this case `hidraw4`. We can now make it available to the VM:

```bash
crosh> vmc key-attach termina /dev/hidraw4
Security key at /dev/hidraw4 shared with vm termina at port=1
```

Now, in the VM:

```bash
crosh> vmc start termina
(termina) chronos@localhost ~ $ dmesg
# ...
[ 3731.042213] usb 1-1: new full-speed USB device number 3 using xhci_hcd
[ 3731.181342] hid-generic 0003:18D1:F1D0.0001: hiddev96,hidraw0: USB HID v1.10 Device [HID 18d1:f1d0] on usb-0000:00:0c.0-1/input0
```

We can't do much with it yet, since this VM is pretty locked-down. But
we can make it available to containers:

```bash
(termina) chronos@localhost ~ $ lxc config device add lxc-nixos /dev/hidraw0 unix-char source=/dev/hidraw0 uid=1000 required=false
Device /dev/hidraw0 added to lxc-nixos
```

Then, from the container:

```fish
(termina) chronos@localhost ~ $ lxc exec lxc-nixos fish
Welcome to fish, the friendly interactive shell
Type help for instructions on how to use fish
root@lxc-nixos ~# lsusb
unable to initialize usb specBus 001 Device 001: ID 1d6b:0002 Linux 6.6.76-08096-g300882a0a131 xhci-hcd xHCI Host Controller
Bus 001 Device 003: ID 18d1:f1d0
Bus 002 Device 001: ID 1d6b:0003 Linux 6.6.76-08096-g300882a0a131 xhci-hcd xHCI Host Controller
root@lxc-nixos ~#
```

Great! Note how _something_ is happening to the device identifier, which now
shows as `18d1:f1d0`. That is because it is a _virtual_ U2F device [exposed
by `crosvm`](https://crosvm.dev/book/devices/virtual_u2f.html), the virtual
machine manager powering all this.

I had previously created an SSH key in there. Let's retrieve it:

```fish
[I] aldur@lxc-nixos ~ > ssh-keygen -K
Enter PIN for authenticator:
You may need to touch your authenticator to authorize key download.
Enter passphrase for "id_ed25519_sk_rk" (empty for no passphrase):
Enter same passphrase again:
Saved ED25519-SK key to id_ed25519_sk_rk
[I] aldur@lxc-nixos ~> cat id_ed25519_sk_rk.pub
sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIALcxr05U12C5ice6vEPjHjvjnNsGb2ARcF2jLxDleyWAAAABHNzaDo= ssh:
```

There we go!

#### End of line

Unfortunately, this is where things break — end of the line, apparently. When
trying to authenticate through the key, the process will _freeze_ and,
occasionally, bring the whole VM with it. This seems to happen when the Yubikey
checks for user presence (i.e., it blinks and wants you to touch it):

```bash
[I] aldur@lxc-nixos ~> ssh -F /dev/null -i id_ed25519_sk_rk git@github.com
Confirm user presence for key ED25519-SK SHA256:4ARi+YMB8t5EoquC/ZbNCfD62gI+/ObXwMa/TYj5oZo
Enter PIN for ED25519-SK key id_ed25519_sk_rk:
Confirm user presence for key ED25519-SK SHA256:4ARi+YMB8t5EoquC/ZbNCfD62gI+/ObXwMa/TYj5oZo
# Here the process freezes...
```

I tried a few things around this: neither the `root` user nor giving the
container full privileges helped. I also played around with
[`go-libfido2`][1] and peeked at the
debug logs of `libfido2`, just to discover that the communication with the
security key seems to get stuck at different, non-deterministic steps of the
protocol.

Puzzled, I cried for help on the [`crosvm-dev` mailing
list](https://groups.google.com/a/chromium.org/g/crosvm-dev/c/D5iCnoTk-4k/m/Q6u8xk9DAQAJ),
where the developer that originally added this feature was kind enough to
answer that, in fact, this does not support FIDO2 but the older U2F / Fido1
mode. Bummer! Still, worth a try.

I have not yet looked at the code that implements this features in `crosvm`,
but I wonder how big a lift would it be to add support for FIDO2. One day, maybe!

[0]: https://chromeos.dev/en/linux
[1]: https://github.com/keys-pub/go-libfido2
