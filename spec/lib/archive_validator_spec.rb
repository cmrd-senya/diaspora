# frozen_string_literal: true

describe ArchiveValidator do
  let(:json_string) { "{}" }
  let(:json_file) { StringIO.new(json_string) }
  let(:archive_validator) { ArchiveValidator.new(json_file) }

  describe "#validate" do
    context "when bad json passed" do
      let(:json_string) { "#@)g?$0" }

      it "contains critical error" do
        archive_validator.validate
        expect(archive_validator.errors).to include(
          "Bad JSON provided: lexical error: invalid char in json text.\n"\
          "                                       \#@)g?$0\n"\
          "                     (right here) ------^\n"
        )
      end
    end

    it "sets errors from critical validators and warnings from non-critical validators" do
      class TestCriticalValidator
        def initialize(*); end

        def messages
          ["test critical error"]
        end
      end

      class TestNonCriticalValidator
        def initialize(*); end

        def messages
          ["test non critical error"]
        end
      end

      expect(ArchiveValidator).to receive(:critical_validators).and_return([TestCriticalValidator])
      expect(ArchiveValidator).to receive(:non_critical_validators).and_return([TestNonCriticalValidator])
      archive_validator.validate
      expect(archive_validator.errors).to eq(["test critical error"])
      expect(archive_validator.warnings).to eq(["test non critical error"])
    end
  end

  describe ".critical_validators" do
    it "contains default critical validators" do
      expect(ArchiveValidator.critical_validators).to match_array(
        [
          ArchiveValidator::SchemaValidator,
          ArchiveValidator::AuthorPrivateKeyValidator
        ]
      )
    end
  end

  describe ".non_critical_validators" do
    it "contains default non critical validators" do
      expect(ArchiveValidator.non_critical_validators).to match_array(
        [
          ArchiveValidator::ContactsValidator,
          ArchiveValidator::RelayablesValidator,
          ArchiveValidator::OthersDataValidator
        ]
      )
    end
  end
end
