---
title: 'Exporting Excalidraw SVGs and inverting their colors in dark mode'
date: 2025-07-13
---

I am a fan on [Excalidraw](https://excalidraw.com): I use it for quick
sketches, as a whiteboard, and even to produce diagrams that end up in work
writing and on this blog.

For a while, a [long-standing
bug](https://github.com/excalidraw/excalidraw/issues/4190) butchered fonts in
SVG exports. This forced me to export diagrams in PNG and then convert them to
WebP. I got the job done, but with downsides: quality, file size, and losing all
those nice, programmatic features that vectors provide. 

That bug has since been
[fixed](https://github.com/excalidraw/excalidraw/pull/8012) and I can now embed
SVGs directly. Plus, I can now scratch another hitch I had: adjusting
figure colors based on the client's theme. The image below shows what I mean:

{:.text-align-center}
![The text "Hello, vector world!", displaying in black on a light theme and in white on a dark theme.](../images/hello_vector_world.svg){:.centered.inverted}
_Go ahead and change the theme by clicking on the header icon. This image will automatically switch colors as well._

Under the hood, this CSS filter does its magic, inverting the SVG colors on a dark theme.

```css
@media (prefers-color-scheme: dark) {
  img.centered.inverted {
    filter: invert(1);
  }
}
```

As you can see, this filter is pretty naive: it just inverts all colors. I
haven't dug into it yet, but it might be possible to replicate Excalidraw's own
CSS here to adjust all colors to a different palette in dark mode.

To render it in Markdown, I use [Block Inline Attribute Lists](https://boringrails.com/tips/jekyll-css-class):

{% raw %}
```md
{:.text-align-center}
![Alt text]({% link img_path %}){:.centered.inverted}
```
{% endraw %}
