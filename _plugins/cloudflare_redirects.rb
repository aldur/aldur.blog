# frozen_string_literal: true

module Jekyll
  class CloudflareRedirectsGenerator < Generator
    safe true
    priority :lowest

    def generate(site)
      rules = (site.docs_to_write + site.pages).flat_map do |document|
        target = File.join('/', site.baseurl.to_s, document.url)
        Array(document.data['redirect_from']).flat_map do |source|
          # Include the paths that Cloudflare uses for HTML files.
          public_source = source.sub(%r{/index\.html\z}, '/').sub(/\.html\z/, '')
          [source, public_source].uniq.map do |path|
            "#{File.join('/', site.baseurl.to_s, path)} #{target} 301"
          end
        end
      end

      page = PageWithoutAFile.new(site, site.source, '', '_redirects')
      page.content = rules.uniq.sort.join("\n") + "\n"
      page.data['layout'] = nil
      page.data['sitemap'] = false
      site.pages << page
    end
  end
end
