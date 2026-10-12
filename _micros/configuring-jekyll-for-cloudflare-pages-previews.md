---
title: 'Configuring Jekyll for Cloudflare Pages previews'
date: 2026-03-21 18:20:00 +0200
related:
  - _posts/2023-10-15-migrating-to-cloudflare-pages.md
---

[Cloudflare Pages][0] previews deployments at
`<branch-or-commit>.<project>.pages.dev`. Those previews are useful to review
content and layout and to test specific features (e.g., OpenGraph integration
and RSS feed/sitemap generation, which can be validated once online through
third party tools). For those features to work correctly, Jekyll needs to know
the `url` at which it is serving its assets.

Cloudflare builders expose the URL for previews through the [`CF_PAGES_URL`
environmental variable][1]. We can make Jekyll aware of it through this
`build_cloudflare.sh` script:

```bash
configs="_config.yml"

if [ -n "${CF_PAGES_URL:-}" ]; then
  echo "url: $CF_PAGES_URL" > _cf_url.yml
  configs="${configs},_cf_url.yml"
fi

bundle exec jekyll build --config "$configs"
```

To run it, set the script as the build command in your Cloudflare Workers and
Pages configuration.

[0]: https://developers.cloudflare.com/pages/configuration/preview-deployments/
[1]: https://developers.cloudflare.com/pages/configuration/build-configuration/#environment-variables
