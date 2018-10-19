# frozen_string_literal: true

class ArchiveValidator
  # We have to validate relayables before import because during import we'll not be able to fetch parent anymore
  # because parent author will point to ourselves.
  class RelayableValidator < BaseValidator
    include EntitiesHelper

    def initialize(archive_hash, relayable)
      @relayable = relayable
      super(archive_hash)
    end

    private

    def validate
      self.valid = parent_present?
    end

    attr_reader :relayable
    alias object relayable

    # TODO: use diaspora federation to fetch parent where possible
    # For own relayables we could just use RelatedEntity.fetch;
    # For others' relayables we should check the present "own posts" first, and then if the target post is missing from
    # there we could try to fetch it with RelatedEntity.fetch.

    # Common methods used by subclasses:

    def missing_parent_message
      messages.push("Parent entity for #{self} is missing. Impossible to import, ignoring.")
    end

    def parent_present?
      parent.present? || (missing_parent_message && false)
    end

    def parent
      @parent ||= find_parent
    end

    def find_parent
      if entity_type == "poll_participation"
        post_find_by_poll_guid(parent_guid)
      else
        post_find_by_guid(parent_guid)
      end
    end

    def post_find_by_guid(guid)
      posts.find {|post|
        post.fetch("entity_data").fetch("guid") == guid
      }
    end

    def post_find_by_poll_guid(guid)
      posts.find {|post|
        post.fetch("entity_data").fetch("poll", nil)&.fetch("entity_data", nil)&.fetch("guid", nil) == guid
      }
    end
  end
end
