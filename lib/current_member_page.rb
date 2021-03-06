# frozen_string_literal: true

require 'scraped'
require_relative 'membership_row'

class CurrentMemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :id do
    url.to_s.split('/').last
  end

  field :name do
    raw_name.sub(/^Dr /, '').tidy
  end

  field :sort_name do
    noko.css('title').text.split(' - ').first.tidy
  end

  field :photo do
    body.css('.document-panel__img img/@src').last.text
  end

  field :email do
    body.css('a.square-btn/@href').inner_text.gsub('mailto:', '')
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
    noko.css('.body-text').xpath('(//table[.//thead//td//p[.="Party"]])[1]//tbody//tr[td]').map do |tr|
      fragment tr => MembershipRow
    end
  end

  private

  def body
    noko.css('div.koru-side-holder')
  end

  def raw_name
    body.css("div[role='main'] h1").text.sub(/^(Rt )?Hon /, '').tidy
  end
end
