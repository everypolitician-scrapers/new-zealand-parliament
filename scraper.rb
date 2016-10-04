#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'

require 'colorize'
require 'pry'
# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'

require 'scraped_page_archive/open-uri'

TERM = 51

def noko(url)
  Nokogiri::HTML(open(url).read)
end

def datefrom(date)
  Date.parse(date)
end

def formatdate(date)
  return if date.to_s.strip.empty?
  parsed_date = datefrom(date).to_s
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
    id:         mp_url.split("/")[-2],
    name:       body.css("div[role='main']").css('h1').inner_text,
    sort_name:  link.inner_text.strip,
    photo:      body.css('.document-panel__img img/@src').last.text,
    email:      body.css('a.square-btn').attr('href').inner_text.gsub('mailto:',''),
    facebook:   body.css('div.related-links__item a[@href*="facebook"]/@href').text,
    twitter:    body.css('div.related-links__item a[@href*="twitter"]/@href').text,
    term:       TERM,
    source:     mp_url
  }

  data[:photo] = URI.join(mp_url, data[:photo]).to_s unless data[:photo].to_s.empty?

  body.css('.informaltable tr').each do |row|
    data[:area]       = row.css('td')[0].inner_text
    data[:party]      = row.css('td')[1].inner_text
    data[:start_date] = formatdate(row.css('td')[2].inner_text.split("-").first)
    data[:end_date]   = formatdate(row.css('td')[2].inner_text.split("-").last)

    ScraperWiki.save_sqlite([:id, :term, :start_date], data)
  end

  added += 1

end
puts "  Added #{added} members"
