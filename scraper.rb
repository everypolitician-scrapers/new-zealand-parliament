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

class CurrentMemberPage < Scraped::HTML
  field :id do
    url.to_s.split("/")[-2]
  end

  field :name do
    raw_name.sub(/^Dr /,'').tidy
  end

  field :sort_name do
    noko.css('title').text.split(' - ').first.tidy
  end

  field :party do
    latest_membership[1].text.tidy
  end

  field :area do
    latest_membership[0].text.tidy
  end

  # TODO extract all memberships in the current term
  field :start_date do
    sd = '%d-%02d-%02d' % latest_membership[2].text.tidy.split('/').reverse.map(&:to_i)
    sd > '2014-09-20' ? sd : '2014-09-20'
  end

  # TODO use absolute URL decorator
  field :photo do
    raw = body.css('.document-panel__img img/@src').last.text
    return if raw.to_s.empty?
    URI.join(url, raw).to_s
  end

  field :email do
    body.css('a.square-btn').attr('href').inner_text.gsub('mailto:','')
  end

  field :facebook do
    body.css('div.related-links__item a[@href*="facebook"]/@href').text
  end

  field :twitter do
    body.css('div.related-links__item a[@href*="twitter"]/@href').text
  end

  field :term do
    51
  end

  field :source do
    url.to_s
  end

  field :honorific_prefix do
    'Dr' if raw_name.start_with? 'Dr '
  end

  private

  def body
    noko.css('div.koru-side-holder')
  end

  def raw_name
    body.css("div[role='main'] h1").text.sub(/^(Rt )?Hon /,'').tidy
  end

  def latest_membership
    body.css('.informaltable tr').first.css('td')
  end
end

current = 'https://www.parliament.nz/en/mps-and-electorates/members-of-parliament/'
cur_res = Scraped::Request.new(url: current).response

r = CurrentMembersPage.new(response: cur_res)
r.member_urls.each do |url|
  data = CurrentMemberPage.new(
    response: Scraped::Request.new(url: url).response
  ).to_h
  ScraperWiki.save_sqlite([:id, :term], data)
end

