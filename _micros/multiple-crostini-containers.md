---
title: 'Multiple Crostini containers in ChromeOS < 141'
date: 2025-06-19
tags: [ChromeOS]
---

ChromeOS < 141 provides an experimental UI for creating and managing multiple
Crostini containers. When enabled, it improves UX and allows to:

- Launch our container by clicking on its name in the terminal, instead of
  going through `crosh`. If the VM is off, it will launch it as well.
- Mount folders into the container from the Files application.
- Browse the container user home directory through Files.

To enable it, navigate to: `chrome://flags/#crostini-multi-container`, switch
the drop-down to "Enabled" and then restart.

Now, go to: Settings → Linux → Manage extra containers → Create. Fill in the
"Container name" with `lxc-nixos` and click on Create (importantly, do this
_after_ you have created the container from `crosh`). If the container was
previously running, stop it first with `lxc stop`. You can now start it from
Terminal.

{:.text-align-center}
![A screenshot showing the `lxc-nixos` container available in the Terminal application.](../images/chromeos-terminal-lxc-nixos.webp){:.centered}
_The experimental UI makes it seamless to start and access the container from
Terminal._

{:.text-align-center}
![A screenshot showing the `lxc-nixos` container available in the Files application.](../images/chromeos-files-lxc-nixos.webp){:.centered}
_Use Files to browse the container home and mount directories into it._
