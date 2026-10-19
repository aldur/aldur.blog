# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require_relative "../bin/check_markdown_references"

options = { "input" => "GFM" }
valid = <<~'MARKDOWN'
  [Link][target] and ![Image][target] and [target][] and [target].
  [Wrapped
  link][TARGET]
  A footnote[^note].

  [target]: https://example.com
  [^note]: A note.

  \[Literal brackets\]
  `[Example][missing]`

  ```markdown
  [Example][missing]
  ```

      [Indented example][missing]

  <!-- [Comment][missing] -->
MARKDOWN
raise "Valid references failed" unless MarkdownReferences.errors(valid, options).empty?

{
  "[Link][missing]" => "missing",
  "![Image][missing]" => "missing",
  "[missing][]" => "missing",
  "[missing]" => "missing",
  "[Wrapped\nlink][missing]" => "missing",
  "Footnote[^missing]." => "missing",
  "<div markdown=\"1\">\n[Link][missing]\n</div>" => "missing",
  "[Link][missing]\n\n```markdown\n[missing]: https://example.com\n```" => "missing",
}.each do |content, label|
  errors = MarkdownReferences.errors(content, options)
  raise "Missing reference not detected: #{content.inspect}" unless errors.any? { |error| error.include?(label) }
end

Dir.mktmpdir("markdown-references-") do |root|
  File.write(File.join(root, "_config.yml"), "collections:\n  micros:\n    output: true\n")
  sources = ["_posts/2999-01-01-post.md", "_micros/micro.md", "_drafts/draft.md", "pages/page.md"]
  sources.each do |path|
    FileUtils.mkdir_p(File.dirname(File.join(root, path)))
    File.write(File.join(root, path), "---\ntitle: Example\n---\n\n[Link][missing]\n")
  end

  errors = MarkdownReferences.check(root)
  sources.each do |path|
    raise "Missing source location: #{path}:5" unless errors.any? { |error| error.include?("#{path}:5:") }
  end
end

puts "Markdown reference regression checks passed."
