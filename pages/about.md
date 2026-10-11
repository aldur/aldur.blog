---
layout: page
title: About
permalink: /about/
---

Hey! I am Adriano, {% include github_link.html url="https://github.com/aldur/"
text="aldur" %} on GitHub. Welcome to my blog! 👋

{{ site.about.long }}

I hope you enjoy reading this blog. If you'd like to stay up-to-date, you can
[subscribe via RSS]({{ site.feed.path | default: 'feed.xml' | absolute_url }}).
If you'd like to chat, please do! Find me [via mail](mailto:{{
site.author.email }}) or on [Bluesky]({{ site.minima.social_links | where:
"icon", "bluesky" | map: "url" | first }}). If you need to get in touch
securely, here are [my PGP public keys]({{ site.author.pgp_pk_url }}){: data-no-icon="true" }.
