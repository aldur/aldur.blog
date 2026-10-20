# frozen_string_literal: true

require "jekyll"
require "json"
require "tmpdir"
require "open3"
require "bundler"
require_relative "../_plugins/relative_links_multiline"

module RenderedLinks
  BASEURL = "/__linkcheck__"
  CHECKER = File.join(__dir__, "check_rendered_links.py")

  def self.build_preview(config)
    site = Jekyll::Site.new(config.merge("baseurl" => BASEURL))
    site.process
    sources = (site.pages + site.docs_to_write).to_h do |document|
      [Pathname.new(document.destination(site.dest)).relative_path_from(Pathname.new(site.dest)).to_s,
       document.relative_path]
    end
    File.write(File.join(site.dest, ".sources.json"), JSON.generate(sources))
  end

  def self.check_preview(destination)
    # HTMLProofer uses a separate Nix bundle.
    Bundler.with_unbundled_env { Open3.capture3("python3", CHECKER, destination) }
  end
end

if $PROGRAM_NAME == __FILE__
  root = File.expand_path("..", __dir__)
  Dir.mktmpdir("rendered-links-") do |temporary|
    Dir.chdir(root) do
      config = Jekyll.configuration("source" => root, "destination" => File.join(temporary, "site"),
                                    "future" => true, "show_drafts" => true)
      RenderedLinks.build_preview(config)
      stdout, stderr, status = RenderedLinks.check_preview(config["destination"])
      puts stdout
      warn stderr unless stderr.empty?
      abort "Rendered link checks failed." unless status.success?
    end
  end
end
