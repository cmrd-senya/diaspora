# frozen_string_literal: true

describe ArchiveImporter::OwnRelayableImporter do
  shared_examples "it doesn't import if the relayable is known for old user" do
    let(:old_person) { relayable.author }
    let(:new_user) { FactoryGirl.create(:user) }
    let(:entity) { Diaspora::Federation::Entities.build(relayable) }
    let(:instance) { described_class.new(entity.to_json.as_json, new_user) }

    it "doesn't import if the comment known for old user" do
      expect {
        instance.import
      }.not_to raise_error
      expect(relayable.reload.author).to eq(old_person)
    end
  end

  describe "#import" do
    context "with comment" do
      let(:relayable) { FactoryGirl.create(:comment, author: FactoryGirl.create(:user).person) }

      include_examples "it doesn't import if the relayable is known for old user"

      context "with unknown relayable" do
        let(:relayable) { FactoryGirl.build(:comment, author: FactoryGirl.create(:user).person) }

        it "imports correctly" do
          expect {
            instance.import
          }.not_to raise_error

          expect(Comment.find_by(guid: relayable.guid)&.author).to eq(new_user.person)
        end
      end
    end

    context "with like" do
      let(:relayable) { FactoryGirl.create(:like, author: FactoryGirl.create(:user).person) }

      include_examples "it doesn't import if the relayable is known for old user"
    end
  end
end
