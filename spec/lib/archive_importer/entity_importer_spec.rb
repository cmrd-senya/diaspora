# frozen_string_literal: true

describe ArchiveImporter::EntityImporter do
  # TODO

  let(:status_message) { FactoryGirl.create(:status_message) }
  let(:instance) { ArchiveImporter::EntityImporter.new(json, nil) }
  let(:json) { JSON.parse(<<~JSON) }
    {
      "entity_data" : {
         "created_at" : "2015-10-19T13:58:16Z",
         "guid" : "5ecf5f3058970133e5592ae21c0ab87d",
         "parent_guid" : "#{status_message.guid}",
         "text" : "test comment",
         "author" : "author@example.com"
      },
      "entity_type" : "comment",
      "property_order" : [
         "author",
         "guid",
         "parent_guid",
         "text",
         "created_at"
      ]
    }
  JSON

  describe "#import" do
    it "rescues DiasporaFederation::Discovery::InvalidDocument" do
      stub_request(:get, "https://example.com/.well-known/webfinger?resource=acct:author@example.com") do
        raise "Failure"
      end

      stub_request(:get, "https://example.com/.well-known/host-meta") do
        raise DiasporaFederation::Discovery::InvalidDocument
      end

      expect {
        instance.import
      }.not_to raise_error
    end
  end
end
