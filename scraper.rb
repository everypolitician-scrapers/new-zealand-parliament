#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'pry'
require 'scraped'
require 'scraperwiki'
require 'csv'
require 'combine_popolo_memberships'
require 'require_all'

require_rel 'lib'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

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
  ScraperWiki.save_sqlite(%i(id term start_date), allmems)
end
