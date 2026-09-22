---
layout: post
title: 'Bare-minimum Google indexing for Jekyll'
categories: [articles]
last_modified_at: 2024-02-26
---

Searching for this blog on Google right now does not return any results. Let's
fix that.

If you think about it, that makes sense! If there are no links pointing to this
blog, Google cannot follow them to find it and index it[^analytics]. Luckily we
can _welcome_ Google's crawlers here by:

1. Adding a new "property" for this blog to the "Google Search Console".
1. Verifying we own the "property".
1. Ensuring that Google crawlers will find all articles by populating
   `sitemap.xml` and `robots.txt` files.

#### Adding and verifying a new property

[This Google support
page](https://support.google.com/webmasters/answer/34592?hl=en#zippy=%2Cdomain-property-examplecom)
shows how add the property. We are using a
[Cloudflare Pages'](2023-10-15-migrating-to-cloudflare-pages.md) domain, so we
don't control DNS, and we will need to create a URL-prefix property.

To verify the URL-prefix we need the following snippet within the `<head>` of
our index:

```html
<meta name="google-site-verification" content="<verification-token-provided-by-Google>" />
```

I first considered doing this by hand, but then found out that the
[jekyll-seo-tag](https://github.com/jekyll/jekyll-seo-tag/) plugin[^seo-tag]
supports this. Adding a `google_site_verification` entry to the {% include
github_link.html url="https://github.com/aldur/aldur.github.io/pull/15"
text="site configuration" %} and deploying the change was enough to complete the
verification.

#### Indexing content

Next, we want web crawlers to index all articles. In _theory_ (based on
"how-Google-works-101"), crawlers will follow links as they find them, and
having all articles listed in the blog index should be enough. But who knows
what really goes on behind the scenes?

A [sitemap](https://www.sitemaps.org) provides a more robust solution, listing
all entries in an XML document (similar to an RSS feed). The
[jekyll-sitemap](https://github.com/jekyll/jekyll-sitemap) plugin takes care of
populating it and updating it with new articles.

<div class="warning" markdown="1">
The behaviour of the sitemap plugin depends on the index at which we add it to
Jekyll's `plugins` array in the site configuration.
</div>

<div class="hint" markdown="1">
In my case, I added it _last_ -- it "knows" _not_ to add my RSS feed to the sitemap
and I want it to index the rest of the content.
</div>

By [adding a `robots.txt`
file](https://developers.google.com/search/docs/crawling-indexing/robots/create-robots-txt)
we inform bots about the sitemap:

```txt
User-agent: *
Sitemap: https://aldur.pages.dev/sitemap.xml
```

Jekyll exposes a `url` configuration entry, which defaults to `localhost` in
development. When deploying on Cloudflare Pages, I override it in a separate
configuration file. We can use Liquid to inject the correct URL using `{{
site.url }}/sitemap.xml`
([credits](https://medium.com/@vilcins/optimize-your-jekyll-powered-website-with-these-simple-steps-b2a24d66a629)).

#### Results

I prepared and merged the {% include github_link.html
url="https://github.com/aldur/aldur.github.io/pull/16" text="changes" %}. Then,
I refreshed Google's `robots.txt` cache (instructions
[here](https://developers.google.com/search/docs/crawling-indexing/robots/submit-updated-robots-txt)).

The Search Console tells me it will take a couple of days to index everything.
I will see how that works out and update this article if I find out there's
anything else I need to do.

If you ended up through a Google search: It worked!

#### Post scriptum

It turns out that _despite_ all above, these days Google will not
index[^indexing] your website unless one of its crawlers finds a reference to
it. In my case, [this tweet](https://twitter.com/swardley/status/1758925267395842521)
triggered some traffic and an email from Google, informing me that I can monitor
incoming traffic from the console. Alas, as of February 2024, the console shows
little traffic but has not picked up any page in the index yet.

#### Footnotes

[^analytics]:
    Unless you use Google Analytics. In that case, I expect that the analytics
    scripts take care of indexing, so you won't need the steps described
    here.

[^seo-tag]:
    The plugin also makes social information and title/excerpts of posts
    available to search crawlers. The [`minima`
        theme](https://github.com/jekyll/minima) I am
    [using](2023-10-07-reboot.md) suggests adding it in its default
    configuration.

[^indexing]:
    In my case, trying to manually request the indexing from the Google Search
    Console got me:

    > Sorry--we couldn't process this request because you've exceeded your daily
    > quota. Please try submitting this again tomorrow.

    I got this on my first request of the day. Is the quota zero?
