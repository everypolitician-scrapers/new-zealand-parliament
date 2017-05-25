# frozen_string_literal: true

require 'cgi'

class CloudflareProtectedEmail
  def initialize(obsfuscated_address:)
    @obsfuscated_address = obsfuscated_address
  end

  def unobsfuscated_address
    CGI.unescape(decrypted_email)
  end

  private

  attr_accessor :obsfuscated_address

  def encrypted_characters
    obsfuscated_address.scan(/.{2}/).drop(1).map(&:hex)
  end

  def key
    @key ||= obsfuscated_address[0..1].hex
  end

  def decrypted_email
    encrypted_characters.reduce('') do |email, encoded_character|
      email + (encoded_character ^ key).to_s(16).prepend('%')
    end
  end
end
