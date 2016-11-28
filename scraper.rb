#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'pry'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  page = noko(url)

  added = 0
  page.css('.list__row').each do |entry|
    link   = entry.css('.theme__link')
    mp_url = URI.join(url, link.attr('href').text)
    mp     = noko(mp_url)
    body   = mp.css('div.koru-side-holder')

    data = {
      id: mp_url.to_s.split("/")[-2],
      name: body.css("div[role='main']").css('h1').inner_text,
      sort_name: link.inner_text.strip,
      party: body.css('.informaltable td')[1].inner_text,
      area:  body.css('.informaltable td')[0].inner_text,
      photo: body.css('.document-panel__img img/@src').last.text,
      email: body.css('a.square-btn').attr('href').inner_text.gsub('mailto:',''),
      facebook: body.css('div.related-links__item a[@href*="facebook"]/@href').text,
      twitter:  body.css('div.related-links__item a[@href*="twitter"]/@href').text,
      term: 51,
      source: mp_url.to_s,
    }
    data[:photo] = URI.join(url, data[:photo]).to_s unless data[:photo].to_s.empty?

    added += 1
    warn data
    ScraperWiki.save_sqlite([:id, :term], data)
  end
  puts "  Added #{added} members"
end

scrape_list 'https://www.parliament.nz/en/mps-and-electorates/members-of-parliament/'
