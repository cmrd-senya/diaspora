# frozen_string_literal: true

class ArchiveImporter
  class EntityImporter
    include ArchiveValidator::EntitiesHelper
    include Diaspora::Logging

    def initialize(json, user)
      @object = json
      @user = user
    end

    def import
      self.persisted_object = Diaspora::Federation::Receive.perform(entity)
    rescue DiasporaFederation::Entities::Signable::SignatureVerificationFailed => e
      logger.warn "#{self}: #{e}"
    end

    attr_reader :object
    attr_reader :user
    attr_accessor :persisted_object

    def entity
      entity_class.from_json(object)
    end
  end
end
