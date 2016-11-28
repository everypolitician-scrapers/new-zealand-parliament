#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'pry'
require 'scraped'
require 'scraperwiki'
require 'csv'
require 'combine_popolo_memberships'

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

class MembershipRow < Scraped::HTML
  field :area do
    td[0].text.tidy
  end

  field :party do
    td[1].text.tidy
  end

  field :start_date do
    '%d-%02d-%02d' % td[2].text.tidy.split('/').reverse.map(&:to_i)
  end

  field :end_date do
    return unless td[3]
    ed = td[3].text.tidy
    return if ed.empty?
    '%d-%02d-%02d' % ed.split('/').reverse.map(&:to_i)
  end

  private

  def td
    noko.css('td')
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

  field :source do
    url.to_s
  end

  field :honorific_prefix do
    'Dr' if raw_name.start_with? 'Dr '
  end

  field :memberships do
    noko.css('.body-text').xpath('//table[.//th[.="Party"]]').first.css('tr').map do |tr|
      MembershipRow.new(response: response, noko: tr).to_h
    end
  end

  private

  def body
    noko.css('div.koru-side-holder')
  end

  def raw_name
    body.css("div[role='main'] h1").text.sub(/^(Rt )?Hon /,'').tidy
  end
end

EPTERMS = 'https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/New_Zealand/House/sources/manual/terms.csv'

all_terms = CSV.parse(
  open(EPTERMS).read, headers: true, header_converters: :symbol
).map(&:to_h)

current = 'https://www.parliament.nz/en/mps-and-electorates/members-of-parliament/'
cur_res = Scraped::Request.new(url: current).response

r = CurrentMembersPage.new(response: cur_res)
r.member_urls.each do |url|
  data = CurrentMemberPage.new(
    response: Scraped::Request.new(url: url).response
  ).to_h
  memberships = data.delete(:memberships).each { |m| m[:id] = data[:id] }
  combined = CombinePopoloMemberships.combine(id: memberships, term: all_terms)

  allmems = combined.map { |mem| data.merge(mem) }.select { |t| t[:term] == '51' }
  ScraperWiki.save_sqlite([:id, :term, :start_date], allmems)
end

