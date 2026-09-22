---
layout: post
title: "Migrating from GitHub Pages to Cloudflare Pages"
categories: [articles]
---

I have recently moved this Jekyll blog from [GitHub
Pages](https://pages.github.com) to [Cloudflare
Pages](https://developers.cloudflare.com/pages/). Here is how I prepared a
smooth migration (trying not to break things along the way).

#### Post outline

- [Cloudflare pages](#cloudflare-pages): what, why
- [The easy steps](#setting-things-up): configuration, test, the docs
  - Managed access
- [The tricky bits](#preparing): a smooth transition
  - Redirect blog posts
  - Dealing with the RSS feed
  - Have we missed anything?
- [The delta](#did-we-break-anything):
  - Relative URLs in RSS feed (?)
- [The light at the end of the tunnel](#wrapping-up):
  - Support for rollbacks, redirects, custom headers, workers

## Cloudflare Pages

I like GitHub Pages! They make it easy to spin up Jekyll websites. GitHub
Actions, then, provide additional space for customization, if one needs to. But
simplicity comes with constraints, too.

In my case, I wanted to add privacy-preserving (and GDPR-compliant) analytics
to the blog. GitHub doesn't provide analytics for pages. [Plausible][0] would
be a good alternative, but the _little_ traffic on this blog doesn't justify
their paid plans; the self-hosted option instead requires spinning up an
instance, securing it, maintaining it, and so on. Not ideal.

That's when I thought about Cloudflare Pages -- their option to serve static
content.

Being integrated into Cloudflare, Pages can measure [privacy-preserving
analytics][9] that don't rely on client state and don't require adding the
most-hated-banner of the web: "_Allow Cookies?_". Also, I have used Cloudflare
to manage DNSs before. If I ever move this to a custom domain, it would be good
to have everything it one place[^censorship].

So, Cloudflare Pages.

## Setting things up

Setting things up was smooth. Their [docs][1] will guide you to create the
Pages project, provide access to the GitHub repository[^reverse_access], and
test the deployment the `*.pages.dev` domain assigned to the project. So far,
so good.

Any trouble? When setting up the deployment, I experimented with their "Access
Policy", that gates who can see pre-deployed versions of the website. Thing is,
once enabled there's no way to disable it through the interface without
onboarding to their "Zero Trust" product. Luckily, we can go the
[API-based approach][2].

Having disabled "Access Policy" and tested the deployment we now have two
versions of the website, respectively served by GitHub and Cloudflare, on two
different domains (`aldur.github.io` and `aldur.pages.dev`).

How do we migrate users from the old domain to the new one?

## Preparing

Let's establish our migration _goals_:

- We want _links_ pointing to existing _resources_ on GitHub to redirect to the
  same resource, on Cloudflare. No generic redirects to the root of the new
  domain that leave the users to find again their destination.
- We also want _previous_ users to remain up-to-date. For that, we need to tell
  "browser users" that the blog has moved and notify _somehow_ RSS users too.

<div class="note" markdown="1">
I talk about users as if there is _a crowd reading this blog_.
I should probably be using a singular form:

> Hello mom! 👋

</div>

What _constraints_ do we have?

- The ideal solution would be responding with a `302` status code. But GitHub
  [doesn't provide][10] dynamic HTTP redirects.
- We'll have to engineer this through what we have: static files, HTML and
  JavaScript (this one if we _really_ need to, as that breaks bots, SEO, etc.).

OK, what's the plan then? We will take the matter into our hands!

#### HTML pages

All HTML pages at GitHub will redirect to their corresponding page at Cloudflare
by using:

- `<meta http-equiv="refresh" content="3;url=https://aldur.pages.dev/[destination]">` and
- `<link rel="canonical" href="https://aldur.pages.dev/[destination]">`.

This informs search-engine bots of the redirect and lets us display an
informative page to the user. There are less than a dozen pages in total. It
takes less to write the HTML code by hand than to script it -- but a Jekyll
plugin could do that automatically.

{:.text-align-center}
![This blog has moved, about page](../images/moved.webp){:.centered}
_What the result looks like for our [about][3] page -- try clicking on the link yourself._

#### The RSS feed

The RSS feed needs special treatment. If someone consumes this blog only through
the feed, they'll need to manually edit the feed URI to get new posts, and we
want to notify them. We will create a static new RSS entry that points to the
new website.

{:.text-align-center}
![This blog has migrated, RSS entry](../images/rss_migration.webp){:.centered}
_The [RSS feed entry][4] showing the notification._

<div class="hint" markdown="1">
[This handy
website](https://validator.w3.org/feed/) lets you validate the static RSS feed
to prevent mistakes.
</div>

#### Anything else?

For sure! Static assets, uploads, and so on. Short of continuing to serve their
original version, there's not much we can do. They are not HTML files, and we
can't redirect a `webp` image without dynamic HTTP redirects. Still, there's
little chance of someone visiting/requesting static assets from the old domain.

This time is OK to compromise. We can use a little JavaScript to:

- Inform the user of what's happening.
- Do our best to redirect them to the right place.

Bonus: If we use a `404.html` file it will also catch and redirect requests to
resources that didn't exist on the old website -- or anything we missed during
the migration. The downside, if you are asking, is that the JavaScript approach
doesn't work with `curl`, bots, and so on.

You can try the resulting feel [here][5].

<div class="note" markdown="1">
{:.text-align-center}
![pages through http-equiv, a custom RSS entry, and JavaScript for anything else](../images/github_to_cloudflare.webp){:.centered}
_The redirection plan completed._
</div>

## Green-light: Migrate!

With all things ready, we can reconfigure our GitHub repository to deploy GitHub
Pages from a specific branch (`redirect_to_cloudflare` in my case). After
pushing our static code there, traffic will migrate to Cloudflare.

The source code is {% include github_link.html
url="https://github.com/aldur/aldur.github.io/tree/redirect_to_cloudflare" text="here" -%}.

<div class="hint" markdown="1">
It is also a good idea to stop ourselves from deleting the branch by mistake:
GitHub allows setting branch protection rules and denoting branches as
_read-only_. That should do it.
</div>

If you are reading this, it means the migration worked 🎉.

## Did we break anything?

So far, I only spotted one difference. Cloudflare's RSS feed doesn't include the
full URI (including the `pages.dev` domain), but only relative URLs. That's
because the [`jekyll-feed` plugin][6] relies
on `site.url` or `site.github.url` (if deployed on GitHub) -- both missing in my
case.

Our RSS validator complains -- and rightly so:

> id must be a full and valid URL: /feed.xml

Interestingly, this doesn't break my RSS reader.

To {% include github_link.html
url="https://github.com/aldur/aldur.github.io/pull/11" text="fix this" %} we
add a Cloudflare-specific configuration file and instruct Cloudflare Pages
to use it while building the site (`jekyll build --config
_config.yml,cloudflare_pages._config.yml` in "Build configuration").

<div class="admonition" markdown="1">
This fix works for the production-version of the website. Unfortunately,
Cloudflare doesn't let specifying different build configs for production and
preview.

After applying the fix, the RSS feeds of deployment previews will point to
the production URL, instead of the preview. Leaving the issue unfixed would not
introduce this issue, because the relative URL would resolve to the correct
domain.

</div>

## Wrapping up

Migrations of live environments need careful handling. They are usually not
_hard_, but can get _complicated_.

In this case, the constraints of GitHub pages also required some ~~hacks~~
innovative solutions. But also the risk was _low_ -- because of the very little
legacy we have.

Looking back, the outcome was good. We now have analytics (and rollbacks!) in
place, the UX of the migration feels good enough, and there's room for more
goodies and growth if the occasion comes (e.g., a custom domain or the addition
of web workers). Also, if the need for a migration arises again, Cloudflare
will provide better flexibility: HTTP [redirects][7] and [headers][8].

#### Footnotes

[^censorship]:
    There are downsides too, of course, as this _centralizes_ the
    Web and adds a "single point of censorship". But that's something for
    another post.

[^reverse_access]:
    By default, Cloudflare integrates with GitHub to
    automatically deploy new versions on push to the repository (even on
    non-production branches to test changes).

    I find it nice, but 1. Cloudflare
    needs to know how to build the website; and 2. has full access to the sources.

    None of these points is an issue for me (the source is public, after all, and
    Jekyll builds are well-supported). But on the first sign of trouble, I would
    switch to pushing the assets to Cloudflare through GitHub actions for more
    control.

[0]: https://plausible.io
[1]: https://developers.cloudflare.com/pages/migrations/migrating-jekyll-from-github-pages/
[2]: https://community.cloudflare.com/t/how-can-i-disable-the-access-policy-of-cloudflare-pages/292358/10
[3]: https://aldur.github.io/about
[4]: https://aldur.github.io/feed.xml
[5]: https://aldur.github.io/foo
[6]: https://github.com/jekyll/jekyll-feed
[7]: https://developers.cloudflare.com/pages/platform/redirects/
[8]: https://developers.cloudflare.com/pages/platform/headers/
[9]: https://www.cloudflare.com/en-gb/web-analytics/
[10]: https://til.simonwillison.net/github/github-pages#user-content-custom-redirects-are-not-supported
