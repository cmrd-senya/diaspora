# frozen_string_literal: true

class ArchiveImporter
  class ContactImporter
    include Diaspora::Logging

    def initialize(json, user)
      @object = json
      @user = user
    end

    attr_reader :object
    attr_reader :user

    def import
      @imported_contact = create_contact
      add_to_aspects
    rescue ActiveRecord::RecordInvalid => e
      logger.warn "#{self}: #{e}"
    end

    private

    def add_to_aspects
      object.fetch("contact_groups_membership", []).each do |group_name|
        aspect = user.aspects.find_by(name: group_name)
        if aspect.nil?
          logger.warn "#{self}: aspect \"#{group_name}\" is missing"
          next
        end
        @imported_contact.aspects << aspect
      end
    end

    def create_contact
      person = Person.by_account_identifier(object.fetch("account_id"))
      user.contacts.create!(person_id: person.id, sharing: object.fetch("sharing"), receiving: false)
    end
  end
end
