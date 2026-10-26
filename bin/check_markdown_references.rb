# frozen_string_literal: true

require "jekyll"
require "kramdown"
require "kramdown-parser-gfm"

module MarkdownReferences
  MISSING_REFERENCE = /\ANo link definition|\AFootnote definition .* not found on line /

  def self.errors(content, options)
    Kramdown::Document.new(content, options).warnings.grep(MISSING_REFERENCE)
  end

  def self.check(source)
    config = Jekyll.configuration("source" => source, "config" => File.join(source, "_config.yml"), "future" => true,
                                  "show_drafts" => true, "quiet" => true)
    site = Jekyll::Site.new(config)
    site.read
    markdown = site.find_converter_instance(Jekyll::Converters::Markdown)

    (site.pages + site.collections.values.flat_map(&:docs)).flat_map do |document|
      next [] unless markdown.matches(document.extname)

      # Keep diagnostics aligned with source lines, including front matter.
      offset = File.readlines(File.expand_path(document.path, source)).length - document.content.lines.length
      errors(document.content, config["kramdown"]).map do |error|
        line = error[/ on line (\d+)\z/, 1].to_i + offset
        "#{document.relative_path}:#{line}: #{error.sub(/ on line \d+\z/, '')}"
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  errors = MarkdownReferences.check(File.expand_path("..", __dir__))
  abort errors.join("\n") unless errors.empty?

  puts "Markdown reference checks passed."
end
