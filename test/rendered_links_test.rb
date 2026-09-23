# frozen_string_literal: true

# Run through the rendered-links check defined in test/tests.nix.
require "jekyll"
require "json"
require "tmpdir"
require "fileutils"
require "open3"
require "bundler"

ROOT = File.expand_path("..", __dir__)
CHECKER = File.join(__dir__, "check_rendered_links.py")
BASEURL = "/__linkcheck__"

def build_preview(config)
  site = Jekyll::Site.new(config.merge("baseurl" => BASEURL))
  site.process
  sources = (site.pages + site.docs_to_write).to_h do |document|
    [Pathname.new(document.destination(site.dest)).relative_path_from(Pathname.new(site.dest)).to_s,
     document.relative_path]
  end
  File.write(File.join(site.dest, ".sources.json"), JSON.generate(sources))
end

def check_preview(destination)
  # HTMLProofer is supplied by Nix with its own bundle, separate from Jekyll.
  Bundler.with_unbundled_env { Open3.capture3("python3", CHECKER, destination) }
end

Dir.mktmpdir("rendered-links-") do |temporary|
  # Exercise the actual Markdown/Liquid pipeline, including the gem's wrapped
  # link bug. These failures must be detected by the rendered-output checker.
  fixture = File.join(temporary, "fixture")
  FileUtils.mkdir_p(File.join(fixture, "_posts"))
  File.write(File.join(fixture, "target.md"), "---\npermalink: /target/\n---\n# Heading\n")
  config = Jekyll.configuration("source" => fixture, "destination" => File.join(temporary, "fixture-site"),
                                "plugins" => ["jekyll-relative-links"], "quiet" => true,
                                "relative_links" => { "collections" => true })
  source = "_posts/2020-01-01-source.md"
  cases = {
    "[Valid](../target.md#heading)" => nil,
    "[Relative](../../../target/#heading)" => nil,
    "[Same page](#source)" => nil,
    "[Wrapped\nlink](../target.md)" => "missing the expected",
    "[Missing](#{BASEURL}/missing.html)" => "missing.html",
    "[Anchor](../target.md#absent)" => "absent",
    "![Missing](#{BASEURL}/missing.png)" => "missing.png",
    "[Escape](../../../../target/)" => "missing the expected",
    "[Wrong prefix](#{BASEURL}-wrong/target/)" => "missing the expected",
    "[External](https://example.invalid/missing)" => nil,
  }
  Dir.chdir(fixture) do
    cases.each do |markdown, expected_error|
      File.write(source, "---\ntitle: Source\n---\n# Source\n\n#{markdown}\n")
      build_preview(config)
      stdout, stderr, status = check_preview(config["destination"])
      if expected_error
        unless !status.success? && (stdout + stderr).include?(expected_error) && (stdout + stderr).include?(source)
          raise "Expected #{expected_error.inspect} for #{markdown.inspect}:\n#{stdout}#{stderr}"
        end
      elsif !status.success?
        raise "Expected valid links for #{markdown.inspect}:\n#{stdout}#{stderr}"
      end
    end
  end
  puts "Rendered link regression checks passed."

  Dir.chdir(ROOT) do
    config = Jekyll.configuration("source" => ROOT, "destination" => File.join(temporary, "site"),
                                  "future" => true, "show_drafts" => true)
    build_preview(config)
    stdout, stderr, status = check_preview(config["destination"])
    puts stdout
    warn stderr unless stderr.empty?
    abort "Rendered link checks failed." unless status.success?
  end
end
