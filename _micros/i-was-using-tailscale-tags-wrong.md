---
title: 'I was using Tailscale tags wrong'
date: 2026-10-12
---

For a while, I'd been manually applying the Tailscale tag `tag:trusted-device`
to my laptop and phone to enable them to access the services on my tailnet (a
single-user, multidevice network).

This mostly worked, but didn't follow Tailscale's [recommendations][0] on tags:

> Only use tags for non-human machines.
> \[...\]
> Do not use tags to:
>
> - Annotate user devices.
> - Link a user device with a user.
> - Authenticate end-user devices, such as laptops or mobile devices.

I am still unsure if my devices are "_human machines_", but this did not play
well with key expiry. Tagged devices normally have key expiry disabled, but
manually adding a tag to an existing device leaves its expiry setting
unchanged. Mine still had expiry enabled. After expiration, signing back in
with my user account would remove the tag, preventing the device from reaching
the services. It would usually take me a while to remember why.

The issue arises because Tailscale tags act as _service accounts_: applying a
tag replaces the device's user-based identity with a tag-based identity. A
tagged device won't be removed from a tailnet if the user that created it is
removed, because the tag _owns_ the device, not the user. This isn't an issue
on my small network, but bad habits tend to stick. So I decided to clean things
up.

I now use tags to identify servers, VMs, and CI runners (e.g.,
`tag:ci-runners`) while keeping personal devices associated with my user
account. I implement access control through two layers:

1. Tailscale's ACLs control device-to-device communication.
1. When a server hosts multiple services through the same port (e.g., 443),
   Caddy controls which devices can access each _service_, based on their
   Tailscale IP addresses.

My IP-based Caddy rules work, but maintaining an IP allowlist isn't ideal: a
device's IP could change, e.g. after uninstalling and reinstalling the
Tailscale app. I might be able to replace the IP allowlist by integrating
Tailscale's [application capabilities][1] with Caddy. I haven't looked into
that yet.

[0]: https://tailscale.com/docs/features/tags#use-cases
[1]: https://tailscale.com/docs/features/access-control/grants/grants-app-capabilities
