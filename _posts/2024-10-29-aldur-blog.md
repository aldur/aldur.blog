---
title: "Migrating to aldur.blog"
last_modified_at: 2025-06-20
excerpt: >
  Transparently migrating this blog to its own domain.
---

As a small reward for managing to write a bit more lately, I decided to set up
a proper domain: here comes [aldur.blog](../index.md)!

This post details the few steps I took to migrate. If it all went as expected,
you might already be there, and you won't notice a thing. If instead you find
anything broken, please let me know (you will find my contact info in the
footer).

## Migrating

We will have to migrate (again) and redirect readers from the previous domain
to the new home.
[Last year](2023-10-15-migrating-to-cloudflare-pages.md#preparing) I built some
experience with it when migrating away from GitHub pages. This time it will be
a bit easier, because the host (Cloudflare) is not changing. We just need to
switch domains, and Cloudflare's redirects will do most of the heavy lifting.

To refresh things, we will need to:

1. [Redirect each page](#redirect-each-page) to the corresponding page on the
   new domain.
1. [Inform your RSS users](#inform-your-rss-users)[^rss].
1. [Take care of SEO](#take-care-of-seo).
1. [Nits and Bits](#nits-and-bits).

### Redirect each page

Our goal here is to redirect each blog post (and the occasional additional page)
to the corresponding item on the new domain.

Cloudflare's docs include an
[article](https://developers.cloudflare.com/pages/how-to/redirect-to-custom-domain/)
to get started with this. If you are following along, you'll have to make a few
modifications:

- The "Bulk Redirect" section has moved to the bottom of the sidebar. Once you
  find it, you'll need to add a redirect _list_ and then a redirect _rule_.
- Differently from what the documentation suggests, you'll need to use your
  concrete `<you>.pages.dev` subdomain, instead of the wildcard. I learned this
  the hard way.
- I chose _not_ to redirect subdomains in the configuration, since that allows
  me to see deployment previews that Cloudflare will publish on subdomains (e.g.
  `<branch>.aldur.pages.dev`) through GitHub integration.
- I started with a `301` return code ("moved temporarily") and then turned it
  into a `302` after testing it for a while.

{:.text-align-center}
![A screnshot from Cloudflare's dashboard showing a 301 redirect from `aldur.page.dev` to `https://aldur.blog`.](../images/bulk_redirect.webp){:.centered}
_You'll need to configure the bulk redirect this way instead of using the
wildcard._

After setting all up and giving Cloudflare a second to propagate the results,
`curl` correctly reports the `301`:

```bash
$ curl -q --head  https://aldur.pages.dev
HTTP/2 301
date: Tue, 29 Oct 2024 09:52:53 GMT
content-type: text/html
content-length: 167
location: https://aldur.blog
```

We could also [redirect `www` to the apex
domain](https://developers.cloudflare.com/pages/how-to/www-redirect/), but since
it is not the 90s anymore, we won't do that.

### Inform your RSS users

Now, I'd like to transparently allow users to continue pulling the RSS feed from
the new domain. Easy! The `301` redirect that we just configured seems to be the
[standard approach](https://www.rssboard.org/redirect-rss-feed) to do that.

I was able to test this[^test_this] by subscribing through my own feed _before_
making the change.

### Take care of SEO

Lastly, we need to [inform search engines](2023-10-30-jekyll-seo.md) about the
change. This blog relies almost exclusively on relative links. It uses absolute
links only where required by standards (e.g., the sitemap and the RSS feed).

{% include github_link.html
url="https://github.com/aldur/aldur.github.io/pull/50" text="This PR" %} updates
Jekyll's URL, used in Cloudflare deployments to create the RSS feed and the
`sitemap.xml`.

In addition, having a root domain means that I could use DNS verification from
the Google Search console. So I removed the custom `meta` tag in the HTML that
I used before to verify my "property".

As a nice bonus Google would not load my `sitemap.xml`.

{:.text-align-center}
![A screnshot from Google Search console showing an error while trying to upload a sitemap.](../images/sitemap_before.webp){:.centered}
_"Impossible to fetch": I consistently got this before, most likely
because of the subdomain._

{:.text-align-center}
![A screnshot from Google Search console successfully upload a sitemap.](../images/sitemap_after.webp){:.centered}
_Green success, even if you don't read Italian._

Hopefully, search engines will now: pickup new posts from the new domain and
redirect traffic and visitors directed to the old one.

Out of abundance of caution, I also tried visiting my `robots.txt` page and
noticed something unexpected:

```bash
$ curl https://aldur.blog/robots.txt
< HTTP/2 301
< date: Wed, 30 Oct 2024 07:32:26 GMT
< content-type: text/html
< location: https://aldur.blog/robots.txt
```

[A quick
search](https://community.cloudflare.com/t/robots-txt-301-redirect-loop/602680)
led me to configure strict SSL settings within Cloudflare (which doesn't hurt
anyway) and seems to have fixed the issue.

### Nits and bits

{% include github_link.html
url="https://github.com/aldur/aldur.github.io/pull/51" text="This PR" %}
updates the email used in the ["About" section](../pages/about.md). If it
starts getting spammed, I will deploy the usual countermeasures.

{% include github_link.html
url="https://github.com/aldur/aldur.github.io/commit/23db5d54315f5e0a93da02bb8c375e9362a28dd6"
text="This commit" %}, instead, redirects the old version at `aldur.github.io`
directly here, avoiding an additional redirect.

There are probably a few other things that I did not migrate (e.g., if you
preferred a light/dark theme instead of using the OS preference, you will need
to re-select it).

But today was long enough, let's call it a day. Thank you for reading and
welcome to my new digital garden 🪴

#### Footnotes

[^rss]:
    Last I checked, I thought that nobody subscribed to the RSS feed. Then I
    remembered that I am a subscriber and my client requests should appear in
    the logs. They don't, because Cloudflare analytics inject a `js` snippet
    into a page's HTML, which doesn't work for the feed XML. So, if you are
    reading this through an RSS client: that's great, please let me know! If you
    aren't yet: [give it a try]({{ '/feed.xml' | relative_url }}), I really
    like it.

[^test_this]: At least with Miniflux, the RSS client I am using.
