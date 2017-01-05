#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'combine_popolo_memberships'
require 'csv'
require 'pry'
require 'require_all'
require 'scraped'
require 'scraperwiki'

require_rel 'lib'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

EPTERMS = 'https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/New_Zealand/House/sources/manual/terms.csv'
all_terms = CSV.parse(
  open(EPTERMS).read, headers: true, header_converters: :symbol
).map(&:to_h)

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
current = 'https://www.parliament.nz/en/mps-and-electorates/members-of-parliament/'
scrape(current => CurrentMembersPage).member_urls.each do |url|
  data = scrape(url => CurrentMemberPage).to_h
  memberships = data.delete(:memberships).map(&:to_h).each { |m| m[:id] = data[:id] }
  combined = CombinePopoloMemberships.combine(id: memberships, term: all_terms)
  current = combined.select { |t| t[:term] == '51' }

  wanted = %i(start_date end_date area party term)
  mems = current.map { |mem| data.merge(mem.keep_if { |k, v| wanted.include? k }) }
  ScraperWiki.save_sqlite(%i(id term start_date), mems)
end
