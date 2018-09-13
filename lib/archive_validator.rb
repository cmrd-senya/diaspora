# frozen_string_literal: true

require "yajl"

# ArchiveValidator checks for errors in archive. It also find non-critical problems and fixes them in the archive hash
# so that the ArchiveImporter doesn't have to handle this issues. Non-critical problems found are indicated as warnings.
# Also it performs necessary data fetch where required.
class ArchiveValidator
  def initialize(archive)
    @archive = archive
  end

  def validate
    run_validators(self.class.critical_validators, errors)
    run_validators(self.class.non_critical_validators, warnings)
  rescue KeyError => e
    errors.push("Missing mandatory data: #{e}")
  rescue Yajl::ParseError => e
    errors.push("Bad JSON provided: #{e}")
  end

  def errors
    @errors ||= []
  end

  def warnings
    @warnings ||= []
  end

  def archive_hash
    @archive_hash ||= Yajl::Parser.new.parse(archive)
  end

  def self.critical_validators
    [
      SchemaValidator,
      AuthorPrivateKeyValidator
    ]
  end

  def self.non_critical_validators
    [
      ContactsValidator,
      RelayablesValidator,
      OthersRelayablesValidator
    ]
  end

  private

  attr_reader :archive

  def run_validators(list, messages)
    list.each do |validator_class|
      validator = validator_class.new(archive_hash)
      messages.concat(validator.messages)
    end
  end
end
