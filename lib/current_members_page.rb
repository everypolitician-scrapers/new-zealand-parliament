# frozen_string_literal: true
require 'scraped'

class CurrentMembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::AbsoluteUrls

  field :member_urls do
    noko.css('.list__row').map do |entry|
      entry.css('a.theme__link/@href').text
    end
  end
end
