---
title: 'Generating OpenGraph images'
date: 2026-03-21 18:43:00 +0200
---

I recently started [syndicating][1] this blog's contents to [Bluesky][2].
While at it, I made a [few improvements][0] to its OpenGraph metadata to make
the display of cards in timelines a bit prettier.

The most noticeable improvement comes from `og:image`, which adds an image on
top of the page title:

{:.text-align-center}
![An image with this blog's name and this post's title, plus the greek letter mu and the site URL](../images/og/micros-2026-03-21-generating-opengraph-images.webp){:.centered style="width: 70%; border-radius: 10px;"}
_The OpenGraph image for this post._

Ideally, I'd dynamically generate all images when running `jekyll build`.
However, the image generation plugin converts an SVG to webp through
`imagemagick`, which isn't available in the Cloudflare builder. As a (ugly)
workaround, I pre-generate each image and [commit it][3] to the repository.

In addition, each post now also includes OpenGraph tags for:

1. Its modified time.
1. Its section (e.g., micros).
1. Its tags (if any).

[0]: https://github.com/aldur/aldur.github.io/pull/134
[1]: https://indieweb.org/POSSE
[2]: https://bsky.app/profile/aldur.blog
[3]: https://github.com/aldur/aldur.github.io?tab=readme-ov-file#opengraph-images
