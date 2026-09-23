# frozen_string_literal: true

require "jekyll-relative-links"

module JekyllRelativeLinks
  # In 0.8, the source matcher excludes newlines in link text. Its HTML
  # fallback loses baseurl and does not handle images. Keep wrapped links on
  # the normal generator path, retaining its permalink and baseurl handling.
  class Generator
    # Allow soft line breaks, but never consume the next paragraph as a label.
    text = %r{((?:!\[[^\]]*\](?:\([^)]*\))?|(?!\]\(|\r?\n[ \t]*\r?\n).)*?)}m
    inline = %r!\[#{text}\]\(\s*([^)]+?)#{FRAG_AND_TITLE_REGEX}\s*\)!
    remove_const(:LINK_REGEX)
    LINK_REGEX = %r!(#{inline}|#{REFERENCE_LINK_REGEX})!.freeze
  end
end
