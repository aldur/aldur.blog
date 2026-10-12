# frozen_string_literal: true

module Jekyll
  # Generator that creates raw markdown files for all posts and micros
  # Allows users to view source by swapping .html for .md in URLs
  class MarkdownPagesGenerator < Generator
    safe true
    priority :lowest # Run last to avoid conflicts

    def generate(site)
      # Process posts
      site.posts.docs.each do |post|
        generate_markdown_file(site, post)
      end

      # Process micros collection if it exists
      if site.collections.key?('micros')
        site.collections['micros'].docs.each do |micro|
          generate_markdown_file(site, micro)
        end
      end
    end

    private

    def generate_markdown_file(site, doc)
      source_path = doc.path
      return unless File.exist?(source_path)

      markdown_content = File.read(source_path, encoding: 'UTF-8')

      # Swap a trailing .html or / for .md, or append it to extensionless URLs.
      url = doc.url.sub(/(?:\.html|\/)\z/, '') + '.md'

      static_file = MarkdownStaticFile.new(site, url, markdown_content)
      site.static_files << static_file
    end
  end

  # Custom static file class for raw markdown content
  class MarkdownStaticFile < StaticFile
    def initialize(site, url, content)
      @site = site
      @content = content
      @base = site.source
      @dir = File.dirname(url)
      @name = File.basename(url)
      @collection = nil
      @relative_path = url
    end

    def write(dest)
      dest_path = destination(dest)
      FileUtils.mkdir_p(File.dirname(dest_path))
      File.write(dest_path, @content, encoding: 'UTF-8')
      true
    end

    def modified?
      true
    end

    def relative_path
      @relative_path
    end

    def destination(dest)
      File.join(dest, @relative_path)
    end

    def url
      @relative_path
    end
  end
end
