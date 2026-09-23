---
title: 'ChromeOS notifications from NixOS'
date: 2026-01-18
tags: [ChromeOS]
---

A few days ago {% include github_link.html
url="https://github.com/aldur/nixos-crostini/commit/ad6a7720ec13eaa970f7f4df83d543cc0df735a2"
text="I extended nixos-crostini" %} to support the `cros-notificationd`
service. NixOS can now display notifications in ChromeOS through Wayland
forwarding.

You can see the result as follows:

```bash
notify-send --app-name="baguette-nixos" "Hello, ChromeOS!"
```

{:.text-align-center}
![A notification sent from NixOS and display in ChromeOS](../images/chromeos-nixos-notifications.webp){:.centered style="width: 50%; border-radius: 10px;"}
_An example notification_
