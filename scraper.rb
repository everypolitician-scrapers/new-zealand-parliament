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
    id: entry.xpath('id').text,
    name: body.css('a[href^=mailto]').text,
    sort_name: entry.xpath('title').text.strip,
    party: entry.xpath('content').text.strip.split(/, /).first,
    area: entry.xpath('content').text.strip.split(/, /).last,
    photo: body.css('td.image img/@src').text,
    email: body.css('a[href^=mailto]/@href').text.gsub('mailto:',''),
    facebook: body.css('div.infoTiles a[@href*="facebook"]/@href').text,
    twitter: body.css('div.infoTiles a[@href*="twitter"]/@href').text,
    term: 51,
    source: mp_url,
  }
  data[:photo].prepend 'http://www.parliament.nz/' unless data[:photo].nil? or data[:photo].empty?
  # puts data
  added += 1
  ScraperWiki.save_sqlite([:name, :term], data)
end
puts "  Added #{added} members"
