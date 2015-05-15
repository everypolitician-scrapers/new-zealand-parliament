#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'
require 'date'

# require 'colorize'
# require 'pry'
# require 'csv'
# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'

def noko(url)
  Nokogiri::HTML(open(url).read) 
end

def datefrom(date)
  Date.parse(date)
end


url = 'http://www.parliament.nz/en-nz/syndication?posting=/en-nz/mpp/mps/current/'
page = noko(url)

added = 0
page.xpath('//entry').each do |entry|
  id = entry.xpath('id').text
  mp_url = entry.xpath('link/@href').text

  mp = noko(mp_url)
  body = mp.css('div.contentBody')

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
  puts data
  added += 1
  ScraperWiki.save_sqlite([:name, :term], data)
end
puts "  Added #{added} members"


