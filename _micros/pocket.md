---
title: 'Zap-It + Miniflux > Pocket'
date: 2025-07-07
---

Three weeks ago, Mozilla [announced][0] that Pocket will shut down tomorrow.
The web received the news with disappointment: Pocket was widely used and
loved.

While many started evaluating alternatives, I won't need to. I have used Pocket
in the past, but two years ago I [switched](../_posts/2023-10-07-zap-it.md) to
a self-hosted solution rocking [Miniflux][1] and [Zap-It][2], a thin Rust
wrapper around an SQLite DB that serves an RSS feed. Miniflux subscribes to the
RSS feed, downloads the full page content and makes it available for reading.

After "zapping" hundreds of articles, I am satisfied with the results.

The stack requires minimum maintenance, has a light footprint, and works
offline thanks to the [Reeder Classic app][3]. Most importantly, I do not
depend on any external service to consume my reading list.

The downsides of self-hosting are usually around maintenance and availability.
I monitor uptime of my setup through [Uptime-Kuma][4] and have just checked the
numbers. Over the last year, Miniflux was up 99.9% of the time. Not bad for a
self-hosted instance with a single customer, myself.

[0]: https://support.mozilla.org/en-US/kb/what-is-pocket
[1]: https://miniflux.app
[2]: https://github.com/aldur/zap-it
[3]: https://reederapp.com/classic/
[4]: https://github.com/louislam/uptime-kuma
