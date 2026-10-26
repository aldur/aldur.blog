# frozen_string_literal: true

require 'jekyll'
require 'tmpdir'
require 'fileutils'
require_relative '../_plugins/cloudflare_redirects'

Dir.mktmpdir('cloudflare-redirects-') do |root|
  source = File.join(root, 'source')
  FileUtils.mkdir_p(File.join(source, '_posts'))
  FileUtils.mkdir_p(File.join(source, '_micros'))
  FileUtils.mkdir_p(File.join(source, '_private'))
  File.write(File.join(source, '_posts/2020-01-01-article.md'), <<~MARKDOWN)
    ---
    title: Article
    permalink: /articles/example
    redirect_from:
      - /short
      - /older.html
      - /nested/index.html
    ---
    Article
  MARKDOWN
  File.write(File.join(source, '_micros/example.md'), <<~MARKDOWN)
    ---
    title: Micro
    date: 2020-01-02
    redirect_from: /micro-short
    ---
    Micro
  MARKDOWN
  File.write(File.join(source, 'about.md'), <<~MARKDOWN)
    ---
    permalink: /about/
    redirect_from: /about-old
    ---
    About
  MARKDOWN
  File.write(File.join(source, '_private/hidden.md'), "---\nredirect_from: /hidden\n---\nHidden")

  [['https://aldur.blog', ''], ['https://test.aldur.pages.dev', '/preview']].each do |url, baseurl|
    destination = File.join(root, baseurl.empty? ? 'production' : 'preview')
    config = Jekyll.configuration('config' => [], 'source' => source, 'destination' => destination,
                                  'url' => url, 'baseurl' => baseurl, 'quiet' => true,
                                  'plugins' => ['jekyll-redirect-from', 'jekyll-sitemap'],
                                  'collections' => { 'micros' => { 'output' => true, 'permalink' => '/micros/:name/' },
                                                     'private' => { 'output' => false } })
    Jekyll::Site.new(config).process

    expected = [
      '/about-old /about/ 301',
      '/micro-short /micros/example/ 301',
      '/nested/ /articles/example 301',
      '/nested/index.html /articles/example 301',
      '/older /articles/example 301',
      '/older.html /articles/example 301',
      '/short /articles/example 301',
    ].map do |rule|
      from, to, status = rule.split
      "#{baseurl}#{from} #{baseurl}#{to} #{status}"
    end
    actual = File.readlines(File.join(destination, '_redirects'), chomp: true)
    raise "Incorrect redirects for #{baseurl.inspect}: #{actual.inspect}" unless actual == expected.sort
    raise 'Redirects file included in sitemap' if File.read(File.join(destination, 'sitemap.xml')).include?('/_redirects')
    raise 'Missing HTML fallback' unless File.file?(File.join(destination, 'short.html'))
    raise 'Missing legacy HTML fallback' unless File.file?(File.join(destination, 'older.html'))
  end
end

puts 'Cloudflare redirect checks passed.'
