# frozen_string_literal: true

# Run through the test-rendered-links target in test/tests.nix.
require "tmpdir"
require "fileutils"
require_relative "../bin/check_rendered_links"

BASEURL = RenderedLinks::BASEURL

Dir.mktmpdir("rendered-links-") do |temporary|
  # Exercise the actual Markdown/Liquid pipeline, including wrapped links.
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
    "[Wrapped\nlink](../target.md#heading)" => nil,
    "[Wrapped destination](\n../target.md#heading\n)" => nil,
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
      RenderedLinks.build_preview(config)
      stdout, stderr, status = RenderedLinks.check_preview(config["destination"])
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
end
