# frozen_string_literal: true

require "integration/federation/federation_helper"

describe ArchiveImporter do
  let(:archive_importer) { ArchiveImporter.new(archive_hash) }

  describe "#import" do
    let(:target) { FactoryGirl.create(:user) }

    context "with duplicates" do
      let(:archive_hash) {
        {
          "user" => {
            "auto_follow_back_aspect" => "Friends",
            "profile"                 => {
              "entity_data" => {
                "author" => "old_id@old_pod.nowhere"
              }
            },
            "contact_groups"          => [{
              "chat_enabled" => true,
              "name"         => "Friends"
            }],
            "followed_tags"           => [target.tag_followings.first.tag.name],
            "post_subscriptions"      => [target.participations.first.target.guid]
          }
        }
      }

      before do
        DataGenerator.create(target, %i[tag_following subscription])
        archive_importer.user = target
      end

      it "doesn't fail" do
        expect {
          archive_importer.import
        }.not_to raise_error
      end
    end

    context "with non-fetchable subscription" do
      let(:archive_hash) {
        {
          "user" => {
            "profile"            => {
              "entity_data" => {
                "author" => "old_id@old_pod.nowhere"
              }
            },
            "post_subscriptions" => ["XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"]
          }
        }
      }

      before do
        stub_request(:get, %r{https*://old_pod\.nowhere/\.well-known/webfinger\?resource=acct:old_id@old_pod\.nowhere})
          .to_return(status: 404, body: "", headers: {})
        stub_request(:get, %r{https*://old_pod\.nowhere/\.well-known/host-meta})
          .to_return(status: 404, body: "", headers: {})

        archive_importer.user = target
      end

      it "doesn't fail" do
        expect {
          archive_importer.import
        }.not_to raise_error
      end
    end
  end

  describe "#create_user" do
    let(:archive_hash) {
      {
        "user" => {
          "auto_follow_back_aspect" => "Friends",
          "profile"                 => {
            "entity_data" => {
              "author" => "old_id@old_pod.nowhere"
            }
          },
          "contact_groups"          => [{
            "chat_enabled" => true,
            "name"         => "Friends"
          }],
          "email"                   => "user@example.com"
        }
      }
    }

    it "creates user" do
      expect {
        archive_importer.create_user("new_name")
      }.to change(User, :count).by(1)
    end
  end
end
