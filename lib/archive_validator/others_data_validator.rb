# frozen_string_literal: true

class ArchiveValidator
  class OthersDataValidator < CollectionValidator
    def collection
      others_relayables
    end

    def entity_validator
      RelayableValidator
    end
  end
end
