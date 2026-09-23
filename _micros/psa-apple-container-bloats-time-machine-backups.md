---
title: 'PSA: Apple container bloats Time Machine backups'
date: 2026-06-18
---

After
[playing with Apple container](../_posts/2026-06-11-nixos-for-apple-container.md),
my Time Machine backups started failing with the error: "The backup disk is
full".

On that particular Mac, the disk is 2TB and I am only allocating 1.5TB to Time
Machine over Samba. That's why the error isn't particularly surprising at first
glance. What's surprising is that `/nix` on the Mac was using almost 1TB and is
_excluded_ from Time Machine, in addition to a few other things (VMs, cache
directories, etc.). As a result, the Samba share should have easily fit what I
needed to back up (plus keep some older copies).

Puzzled, I started investigating. LLMs couldn't pinpoint the exact issue, but
helped me realize that a single Time Machine backup had grown to occupy the
full 1.5TB. Once I discovered that Time Machine mounts the backup image as a
file system under `/Volumes/Backup of <hostname>`, I pointed the great [Disk
Inventory X][0] at it to take a look at what was eating my backup space. Here's
the result:

{:.text-align-center}
![A Disk Inventory X screenshot showing the `snapshot` directory of `com.apple.container` taking more than 500GB of space](../images/disk-inventory-x.webp){:.centered style="width: 70%; border-radius: 10px;"}
_The whole backup is about 540GB, of which 524GB are from `container/snapshot`._

I later found [issue #404 in the `container` repository][1], where multiple
users report the same issue. To prevent this from happening again, you can
exclude the `container` state from your Time Machine backups as follows:

```bash
tmutil addexclusion ~/Library/Application\ Support/com.apple.container
```

Unfortunately, I tried and failed to recover space from the existing bloated
backup, so I just deleted it and started from scratch.

[0]: https://www.derlien.com/
[1]: https://github.com/apple/container/issues/404
