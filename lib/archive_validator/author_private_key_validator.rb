# frozen_string_literal: true

class ArchiveValidator
  class AuthorPrivateKeyValidator < BaseValidator
    def validate
      return if person.nil?
      return if person.serialized_public_key == private_key.public_key.export
      messages.push("Private key in the archive doesn't match the known key of #{person.diaspora_handle}")
    rescue DiasporaFederation::Discovery::DiscoveryError
    end
  end
end
