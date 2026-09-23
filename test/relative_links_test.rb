# frozen_string_literal: true

# Run with: nix develop --command ruby test/relative_links_test.rb
require "jekyll"
require "tmpdir"
require "fileutils"
require_relative "../_plugins/relative_links_multiline"
require_relative "../_plugins/strict_relative_links"

site_config = File.expand_path("../_config.yml", __dir__)

Dir.mktmpdir("relative-links-") do |root|
  Dir.chdir(root) do
    write = lambda do |path, content|
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end
    write.call("_posts/2020-01-01-target.md", "---\ntitle: Target\npermalink: /custom/\n---\nTarget")
    write.call("_micros/target.md", "---\ntitle: Micro\ndate: 2020-01-02\n---\nMicro")
    write.call("pages/about.md", "---\npermalink: /about/\n---\nAbout")
    write.call("_tag_indexes/example.md", "---\ntag: example\n---\nTag")
    write.call("_includes/link.html", '[Included](../pages/about.md)')
    write.call("_includes/broken.html", '[Missing](missing.md)')
    write.call("downloads/source.md", "Downloadable Markdown without front matter")
    write.call("images/example.svg", '<svg xmlns="http://www.w3.org/2000/svg"/>')
    write.call("_posts/2020-01-02-hidden.md", "---\npublished: false\n---\nHidden")
    write.call("excluded.md", "---\n---\nExcluded")

    sources = ["_posts/2020-01-03-source.md", "_micros/source.md", "pages/source.md", "_tag_indexes/source.md"]
    valid_links = <<~MARKDOWN
      [Post](../_posts/2020-01-01-target.md)
      [Micro](../_micros/target.md)
      [Page](../pages/about.md#heading)
      [Collection](../_tag_indexes/example.md)
      [Root](/pages/about.md)
      [Wrapped
      post](../_posts/2020-01-01-target.md#heading)
      [Wrapped destination](
        /pages/about.md#heading
      )

      [An unresolved reference]

      ![Wrapped
      image](/images/example.svg)
      [Wrapped
      reference][about]
      [Reference][about]
      [External](https://example.com/missing.md)
      [Protocol relative](//example.com/missing.md)
      [Anchor](#missing.md)
      [Download]({{ '/downloads/source.md' | relative_url }}?raw=1#heading)
      [Liquid]({% post_url 2020-01-01-target %})
      {% include link.html %}

      `[Example](missing.md)`

      ```markdown
      [Example](missing.md)
      ```

      [about]: ../pages/about.md
    MARKDOWN
    front_matter = "---\ntitle: Source\ndate: 2020-01-03\n---\n"
    sources.each { |path| write.call(path, front_matter + valid_links) }

    build = lambda do |overrides = {}|
      config = Jekyll.configuration("config" => site_config, "source" => root,
                                    "destination" => File.join(root, "_site"), "quiet" => true)
      config.merge!("theme" => nil, "plugins" => ["jekyll-relative-links"],
                    "defaults" => [], "exclude" => ["excluded.md"])
      config.merge!(overrides)
      Jekyll::Site.new(config).tap(&:process)
    end

    ["", "/preview"].each do |baseurl|
      site = build.call("baseurl" => baseurl)
      documents = (site.pages + site.docs_to_write).select { |doc| doc.data["title"] == "Source" }
      raise "Missing source documents" unless documents.size == sources.size

      documents.each do |document|
        { "Post" => "/custom/", "Micro" => "/micros/2020/01/02/target/",
          "Page" => "/about/#heading", "Collection" => "/tags/example.html",
          "Root" => "/about/", "Reference" => "/about/", "Liquid" => "/custom/",
          "Wrapped post" => "/custom/#heading", "Wrapped destination" => "/about/#heading",
          "Wrapped reference" => "/about/",
          "Download" => "/downloads/source.md?raw=1#heading" }.each do |label, url|
          expected = %(<a href="#{baseurl}#{url}">#{label}</a>)
          raise "Incorrect #{label} link in #{document.relative_path}" unless document.output.gsub(/\s+/, " ").include?(expected)
        end
        raise "Incorrect wrapped image" unless document.output.include?(%(src="#{baseurl}/images/example.svg"))
      end
    end

    sources.each do |source|
      ["[Missing](missing.md)", "[Missing\nlink](missing.md)", "[Missing][ref]\n\n[ref]: missing.md",
       "[Hidden](../_posts/2020-01-02-hidden.md)", "[Excluded](/excluded.md)",
       "[Missing](missing.markdown#heading)", "[Missing](missing.md?raw=1)",
       "[Encoded](missing%2Emd)", "{% include broken.html %}",
       "<a class='link' href='missing.md'>Missing</a>"].each do |link|
        write.call(source, front_matter + link)
        begin
          build.call
        rescue Jekyll::Errors::FatalException => error
          raise unless error.message.include?(source) && error.message.include?("Unresolved relative link")
        else
          raise "Expected a build failure in #{source} for #{link.inspect}"
        ensure
          write.call(source, front_matter + valid_links)
        end
      end
    end

    source = sources.first
    write.call(source, front_matter + "[Missing](missing.md)")
    build.call("relative_links" => { "collections" => true, "strict" => false })
    build.call("relative_links" => { "collections" => true, "strict" => true, "enabled" => false })
    build.call("relative_links" => { "collections" => false, "strict" => true })
    build.call("relative_links" => { "collections" => true, "strict" => true, "exclude" => [source] })
  end
end

puts "Relative link checks passed."
