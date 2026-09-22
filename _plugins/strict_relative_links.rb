# frozen_string_literal: true

require "jekyll-relative-links"
require "cgi"
require "pathname"
require "set"

module JekyllRelativeLinks
  # Check after the gem's generators and render hooks have resolved source
  # links. Escaped code examples are not anchors in the rendered HTML.
  class StrictLinks
    ANCHOR_HREF = /<a\b[^>]*?\shref\s*=\s*(["'])(.*?)\1/im

    def initialize(site)
      @site = site
      @markdown = site.find_converter_instance(Jekyll::Converters::Markdown)
      targets = site.pages + site.docs_to_write + site.static_files
      # Include generated Markdown downloads: these are intentional .md URLs.
      @urls = targets.map { |target| normalize(public_path(target.url)) }.to_set
    end

    def check(document)
      return unless @markdown.matches(document.extname)
      return if Hooks.excluded?(document, @site.config, @site)

      document.output.to_s.scan(ANCHOR_HREF) do |_quote, href|
        uri = Addressable::URI.parse(CGI.unescapeHTML(href))
        next if uri.scheme || uri.host || uri.path.to_s.empty?
        next unless @markdown.matches(File.extname(Addressable::URI.unencode(uri.path)))

        base = "https://jekyll.invalid#{public_path(document.url)}"
        path = Addressable::URI.join(base, uri.to_s).path
        next if @urls.include?(normalize(path))

        raise Jekyll::Errors::FatalException,
              "Unresolved relative link in #{document.relative_path}: #{href.inspect}"
      end
    end

    private

    def public_path(url)
      File.join("/", @site.baseurl.to_s, url)
    end

    def normalize(path)
      Pathname.new(Addressable::URI.unencode(path)).cleanpath.to_s
    end
  end
end

Jekyll::Hooks.register :site, :post_render do |site|
  options = site.config.fetch("relative_links", {})
  next if options["enabled"] == false || options["strict"] != true

  checker = JekyllRelativeLinks::StrictLinks.new(site)
  documents = site.pages.dup
  documents.concat(site.docs_to_write) if options["collections"] == true
  documents.each { |document| checker.check(document) }
end
