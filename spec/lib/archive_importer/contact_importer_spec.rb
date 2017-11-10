# frozen_string_literal: true

describe ArchiveImporter::ContactImporter do
  let(:target) { FactoryGirl.create(:user) }
  let(:contact_importer) { described_class.new(import_object, target) }

  describe "#import" do
    context "with duplicating data" do
      let(:contact) { DataGenerator.new(target).mutual_friend.person.contacts.first }
      let(:import_object) {
        {
          "person_guid"               => contact.person.guid,
          "account_id"                => contact.person.diaspora_handle,
          "receiving"                 => contact.receiving,
          "public_key"                => contact.person.serialized_public_key,
          "person_name"               => contact.person.full_name,
          "followed"                  => contact.receiving,
          "sharing"                   => contact.sharing,
          "contact_groups_membership" => [
            contact.aspects.first.name
          ],
          "following"                 => contact.sharing
        }
      }

      it "doesn't fail" do
        expect {
          contact_importer.import
        }.not_to raise_error
      end
    end
  end
end
