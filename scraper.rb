#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'
require 'date'

require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko(url)
  Nokogiri::HTML(open(url).read)
end

def datefrom(date)
  Date.parse(date)
end

base_url = 'https://www.parliament.nz'
url      = "#{base_url}/en/mps-and-electorates/members-of-parliament/"
page     = noko(url)

added = 0
page.css('.list__row').each do |entry|
  link   = entry.css('.theme__link')
  mp_url = link.attr('href').inner_text.prepend(base_url)
  mp     = noko(mp_url)
  body   = mp.css('div.koru-side-holder')

  data = {
    id: mp_url.split("/")[-2],
    name: body.css("div[role='main']").css('h1').inner_text,
    sort_name: link.inner_text.strip,
    party: body.css('.informaltable td')[1].inner_text,
    area:  body.css('.informaltable td')[0].inner_text,
    photo: body.css('.document-panel__img img/@src').last.text,
    email: body.css('a.square-btn').attr('href').inner_text.gsub('mailto:',''),
    facebook: body.css('div.related-links__item a[@href*="facebook"]/@href').text,
    twitter:  body.css('div.related-links__item a[@href*="twitter"]/@href').text,
    term: 51,
    source: mp_url,
  }
  data[:photo] = URI.join(base_url, data[:photo]).to_s unless data[:photo].to_s.empty?

  added += 1
  ScraperWiki.save_sqlite([:name, :term], data)
end
puts "  Added #{added} members"
