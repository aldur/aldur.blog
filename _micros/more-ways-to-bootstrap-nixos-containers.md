---
title: 'Deploying NixOS container images'
date: 2025-07-19
last_modified_at: 2025-07-26
tags: [ChromeOS]
---

This post extends the
[one about NixOS containers in ChromeOS](../_posts/2025-06-19-nixos-in-crostini.md)
with more ways to deploy an `xlc` container image to your host. They might come
handy if you cannot access your Tailscale network or if you can, but the
connection to your image server is proxied and results in slow download speed.

<!--NOTE: If you change this, also change the anchor in the main NixOS on ChromeOS post. -->
### From an LXD image server behind Tailscale

Ubuntu
[documents](https://ubuntu.com/tutorials/create-custom-lxd-images#6-making-images-public)
how to setup an [LXD image
server](https://ubuntu.com/tutorials/create-custom-lxd-images#6-making-images-public):

> Public LXD servers
>
> LXD servers that are used solely to serve images and do
> not run instances themselves.
>
> To make a LXD server publicly available over the network on port 8443, set
> the core.https_address configuration option to :8443 and do not configure any
> authentication methods (see How to expose LXD to the network for more
> information). Then set the images that you want to share to public.

Instead of making the server public, I serve it behind
[Tailscale](https://tailscale.com) from a NixOS server, as follows.

First, enable `lxd` in your NixOS server configuration:

```nix
virtualisation.lxd.enable = true;
```

Rebuild NixOS, then enable the image server as follows:

```bash
# `lxd` can't be configured declaratively in NixOS, go figure!
sudo lxc config set core.https_address :8443
```

Now import the image with:

```bash
lxc image import --public --alias lxc-nixos metadata.tar.xz image.tar.xz
```

Done! Configure the image server on the client and use the image:

```bash
# Replace `tropic` with the hostname of the `lxd` server.
lxc remote add tropic https://tropic:8443 --public
# Ensure you can see the image listed.
lxc image list tropic:
# Download the image and setup the container
lxc init tropic:lxc-nixos lxc-nixos --config security.nesting=true
```

### From local files

Since a container image is just a pair of files, we can get them on the host by
copying them from a physical drive (e.g., a USB stick) or downloading them from
the internet (e.g., from Dropbox, Google Drive, etc.).

This approach simply replaces the Tailscale "public" LXD image server with
another transport to retrieve the images.

<div class="hint" markdown="1">
In ChromeOS, use `crosh` to make the archives available to the `termina` VM:

```bash
vmc share termina Downloads
Downloads is avaiable at path /mnt/shared/MyFiles/Downloads
```

</div>

To use the image:

```bash
lxc image import metadata.tar.xz image.tar.xz --alias lxc-nixos
# `lxc-nixos` represents the image name and the container name
lxc init lxc-nixos lxc-nixos --config security.nesting=true
```

### From Hydra

[Hydra](https://github.com/NixOS/hydra) is the CI service used to build
NixOS. It periodically builds what we need to spin up a bare-minimum NixOS container:

1. `lxdContainerImage`
1. `lxdContainerMeta`

To get it running, I follow these steps through the host's browser:

1. Start [from the nixos project page](https://hydra.nixos.org/project/nixos)
   and pick a recent jobset,
   [release-25.05](https://hydra.nixos.org/jobset/nixos/release-25.05) in my
   case.
1. Pick an [evaluation](https://hydra.nixos.org/eval/1816976).
1. [Search](https://hydra.nixos.org/eval/1816976?filter=lxdContainerMeta&compare=1816955&full=)
   for the job names and pick your host's architecture.
1. Note the [output tarball](https://hydra.nixos.org/build/303157845/download/1/nixos-image-lxc-25.05.806668.f01fe91b0108-x86_64-linux.tar.xz) download link.

At this point, you can use `curl` on the host to download the image and its
metadata through the links you just obtained:

```bash
curl -L https://hydra.nixos.org/build/303157845/download/1/nixos-image-lxc-25.05.806668.f01fe91b0108-x86_64-linux.tar.xz -o metadata.tar.xz
curl -L https://hydra.nixos.org/build/303157857/download/1/nixos-image-lxc-25.05.806668.f01fe91b0108-x86_64-linux.tar.xz -o image.tar.xz
```

You can now import the image:

```bash
lxc image import metadata.tar.xz image.tar.xz --alias lxc-hydra
```

And start the container:

```bash
lxc init lxc-hydra lxc-hydra
lxc start lxc-hydra
lxc exec lxc-hydra bash
```

This will get you into a minimal NixOS container. Add `git` to your path:

```bash
nix --extra-experimental-features nix-command shell --extra-experimental-features flakes nixpkgs#git
```

Then: clone the [repository with your NixOS
configuration](https://github.com/aldur/nixos-crostini), rebuild the container
with `nixos-rebuild --flake` and you are good to go!

The strength of this approach is that it has minimal dependencies. Here are the
downsides: rebuilding NixOS within the container takes time and resources
(e.g., network, and CPU). If you destroy the container, you will need to do it
all again. To avoid that, you can snapshot the container _after_ rebuilding
NixOS and create an image from it.

### From `penguin`

`penguin` is the Debian container shipped in ChromeOS Crostini. You can get it
running as usual, then install `nix` (I typically go for the [Determinate Nix
Installer](https://github.com/DeterminateSystems/nix-installer)), clone the
[repository with your NixOS
configuration](https://github.com/aldur/nixos-crostini) and then build it.

Once built, you can pull the files from the container into the `termina` VM as follows:

```bash
# From `crosh`
vmc termina start
# Now, within `termina`
cd /tmp
lxc file pull penguin//home/aldur/meta.tar.xz .
lxc file pull penguin//home/aldur/image.tar.xz .
```

You can now deploy the image with [the local files](#from-local-files).
