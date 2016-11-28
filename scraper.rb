#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

class CurrentMembersPage < Scraped::HTML
  field :member_urls do
    noko.css('.list__row').map do |entry|
      URI.join(url, entry.css('a.theme__link/@href').text).to_s
    end
  end
end

def noko(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_mp(mp_url)
  mp     = noko(mp_url)
  body   = mp.css('div.koru-side-holder')
  data = {
    id: mp_url.to_s.split("/")[-2],
    name: body.css("div[role='main'] h1").text.sub(/^(Rt )?Hon /,'').tidy,
    sort_name: mp.css('title').text.split(' - ').first.tidy,
    party: body.css('.informaltable td')[1].inner_text,
    area:  body.css('.informaltable td')[0].inner_text.tidy,
    photo: body.css('.document-panel__img img/@src').last.text,
    email: body.css('a.square-btn').attr('href').inner_text.gsub('mailto:',''),
    facebook: body.css('div.related-links__item a[@href*="facebook"]/@href').text,
    twitter:  body.css('div.related-links__item a[@href*="twitter"]/@href').text,
    term: 51,
    source: mp_url.to_s,
  }
  data[:photo] = URI.join(mp_url, data[:photo]).to_s unless data[:photo].to_s.empty?
  data[:honorific_prefix] = 'Dr' if data[:name].sub!(/^Dr /,'')
  warn data
  ScraperWiki.save_sqlite([:id, :term], data)
end

current = 'https://www.parliament.nz/en/mps-and-electorates/members-of-parliament/'
cur_res = Scraped::Request.new(url: current).response

r = CurrentMembersPage.new(response: cur_res)
r.member_urls.each do |url|
  scrape_mp(url)
end

