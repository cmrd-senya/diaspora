# frozen_string_literal: true

describe ArchiveImporter::PostImporter do
  describe "#import" do
    let(:old_person) { post.author }
    let(:new_user) { FactoryGirl.create(:user) }
    let(:entity) { Diaspora::Federation::Entities.build(post) }
    let(:entity_json) { entity.to_json.as_json }
    let(:instance) { described_class.new(entity_json, new_user) }

    context "when post is known for the old user" do
      let!(:post) { FactoryGirl.create(:status_message) }

      it "doesn't import" do
        expect {
          instance.import
        }.to remain(Post, :count)

        expect(post.reload.author).to eq(old_person)
      end
    end

    context "with subscription" do
      let(:post) { FactoryGirl.build(:status_message, public: true) }
      let(:subscribed_person) { FactoryGirl.create(:person) }
      let(:subscribed_person_id) { subscribed_person.diaspora_handle }

      before do
        entity_json.deep_merge!("subscribed_users_ids" => [subscribed_person_id])
      end

      # TODO: rewrite this test when new subscription implementation is there
      xit "creates a subscription for the post" do
        instance.import

        imported_post = Post.find_by(guid: post.guid)
        expect(imported_post).not_to be_nil
        expect(imported_post.participations.first.author).to eq(subscribed_person)
      end

      context "when subscribed user's account is closed" do
        before do
          AccountDeleter.new(subscribed_person).perform!
        end

        # TODO: rewrite this test when new subscription implementation is there
        xit "doesn't create a subscription" do
          instance.import

          imported_post = Post.find_by(guid: post.guid)
          expect(imported_post).not_to be_nil
          expect(imported_post.participations).to be_empty
        end
      end

      context "when subscribed user has migrated" do
        let(:account_migration) { FactoryGirl.create(:account_migration) }
        let(:subscribed_person) { account_migration.old_person }

        # TODO: rewrite this test when new subscription implementation is there
        xit "creates participation for the new user" do
          instance.import

          imported_post = Post.find_by(guid: post.guid)
          expect(imported_post).not_to be_nil
          expect(imported_post.participations.first.author).to eq(account_migration.new_person)
        end
      end

      context "when subscribed user is not fetchable" do
        let(:subscribed_person_id) { "old_id@old_pod.nowhere" }

        it "doesn't fail" do
          stub_request(
            :get,
            %r{https*://old_pod\.nowhere/\.well-known/webfinger\?resource=acct:old_id@old_pod\.nowhere}
          ).to_return(status: 404, body: "", headers: {})
          stub_request(:get, %r{https*://old_pod\.nowhere/\.well-known/host-meta})
            .to_return(status: 404, body: "", headers: {})

          expect {
            instance.import
          }.not_to raise_error
        end
      end
    end
  end
end
