# frozen_string_literal: true
require 'scraped'

class CurrentMembersPage < Scraped::HTML
  field :member_urls do
    noko.css('.list__row').map do |entry|
      URI.join(url, entry.css('a.theme__link/@href').text).to_s
    end
  end
end
