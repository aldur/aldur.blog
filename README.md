# Universal Bits

Personal blog, powered by [Jekyll][0] and the [Minima][4] theme.

## Making changes

- `new "Post Title"` creates a new post.
- `micro "Micro Title"` creates a new micro post. With `-b` it create a new
  branch.

Both commands will set the current date and a _slugify_ the filename.

## Building it

Install [Nix][1] and enable [flakes][2]. Then, run `nix run`.

### Developing

- `nix develop` (or `direnv allow`) is a lean dev shell that allows
  build/serve/write loop.
- `nix develop '.#full'` includes the heavier maintenance tools (`bundix`,
  `html-proofer`).
- `bundler update` will update your Gems. `bundler` is configured to use the
  `vendor` directory, so that it won't try installing it under `nix` store.
- `nix run '.#lock'` will generate the `gemset.nix` file from `Gemfile.lock`.
- `nix flake check` runs the content checks and regression tests.

## Features

### Tags and indexes

Tag posts in their frontmatter with `tags: [tag1, tag2]`. Tags only appear on
posts if there exists a corresponding tag index page. Create one at
`_tag_indexes/<tagname>.md` with:

```yaml
---
tag: tagname
---
```

The tag layout filters all posts with that tag.

### Related reading

Add recommendations to a post or micro's frontmatter:

```yaml
related:
  - _posts/2026-03-12-sandboxing-local-models-on-macos.md
  - _micros/til-ephemeral-qemu-vms.md
```

Use source paths from the repository root, without a leading slash. Missing
targets fail the Jekyll build.

### Excerpts

Configure whether excerpts show (by order of priority):

1. Per post (with `show_excerpt:` in the frontmatter).
1. Per collection (in `_config.yml`, under `collections:`).
1. Default: the value of `show_excerpts:` in `_config.yml` under `minima:`.

### RSS Feeds

RSS feeds are styled to mimic the main blog style and read through continuous
scrolling.

### Copying code

Code blocks show a copy button (when the browser supports JS and clipboard
access).

### Viewing posts as Markdown

Use **view as / copy .md** at the end of a post or micro. You can also view the
source by changing its URL to end with `.md`:

- `page.html` → `page.md`
- `page/` → `page.md`
- `page` → `page.md`

`/llms.txt` indexes posts and micros in markdown.

A generated `_headers` file sets a canonical `Link` HTTP header on each
Markdown copy when served through Cloudflare.

### GitHub link icons

Links to `https://github.com/aldur` automatically get a GitHub SVG icon. Opt
out on a specific link with:

```markdown
[some link](https://github.com/aldur/repo){: data-no-icon }
```

### Custom redirects

Use [`jekyll-redict-from`][3] to add multiple URLs for a page.

```yaml
redirect_from:
  - /short-link
```

The build generates Cloudflare `_redirects` rules from these fields to return
HTTP `301` to the page.

### Opengraph images

The [`og_image`](./_plugins/og_image.rb) plugin generates a per-post
[OpenGraph image][6] (1200x630 WebP) at build time, from an SVG it renders to
WebP. Images are **not** committed: they live under `images/og/` (gitignored)
and are regenerated on every build.

Run `nix run .#og` to force-regenerate all images locally (e.g. to preview a
template change). Use `nix develop .#full` (which includes `pnpm`) to refresh
`pnpm-lock.yaml` after changing dependencies.

### Theme

[Minima's][4] default color follows the user's system preference (light/dark).
The toggle icon overrides it.

### Links

Ordinary Markdown links to files convert to Jekyll URLs through
`jekyll-relative-links`. Paths are relative to the file containing the link, or
relative to the source root when they start with `/`. For example, from a post
in `_posts/`:

```markdown
[Another post](2023-10-07-reboot.md)
[A micro](../_micros/configuring-jekyll-for-cloudflare-pages-previews.md)
[About](../pages/about.md)
[About, from anywhere](/pages/about.md)
```

Reference-style links and `#section` anchors work too. For generated URLs such
as `/feed.xml`, use `{{ '/feed.xml' | relative_url }}`.

[0]: https://jekyllrb.com
[1]: https://nixos.org
[2]: https://nixos.wiki/wiki/Flakes
[3]: https://github.com/jekyll/jekyll-redirect-from
[4]: https://github.com/jekyll/minima
[6]: https://ogp.me
