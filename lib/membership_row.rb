require 'scraped'

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
