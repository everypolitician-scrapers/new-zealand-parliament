# frozen_string_literal: true

require 'scraped'
require_relative 'cloudflare_protected_email'

class DeobfuscatedEmailAddresses < Scraped::Response::Decorator
  def body
    Nokogiri::HTML(super).tap do |doc|
      doc.css('a.square-btn @href').each do |email|
        # Don't try to deobsfuscate the email address when it isn't obsfuscated
        next if email.content.include?('@')
        email.content = CloudflareProtectedEmail.new(obsfuscated_address: email.value.split('%23').last)
                                                .unobsfuscated_address
      end
    end.to_s
  end
end
