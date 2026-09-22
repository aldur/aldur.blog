#!/usr/bin/env bash
set -euo pipefail

# Build script for Cloudflare Pages.
# Uses CF_PAGES_URL for preview deployments so that OG images and canonical
# URLs point to the correct preview domain.

# No need for pnpm install, Cloudflare runs it automatically.

configs="_config.yml,cloudflare_pages._config.yml"

if [ "${CF_PAGES_BRANCH:-}" != "master" ] && [ -n "${CF_PAGES_URL:-}" ]; then
  echo "url: $CF_PAGES_URL" >_cf_preview.yml
  configs="${configs},_cf_preview.yml"
fi

bundle exec jekyll build --config "$configs"
