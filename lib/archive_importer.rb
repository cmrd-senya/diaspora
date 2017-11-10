# frozen_string_literal: true

class ArchiveImporter
  include ArchiveHelper
  include Diaspora::Logging

  attr_accessor :user

  def initialize(archive_hash)
    @archive_hash = archive_hash
  end

  def import
    import_tag_followings
    import_aspects
    import_contacts
    import_posts
    import_relayables
    import_subscriptions
    import_others_relayables
  end

  def create_user(username, email=nil)
    allowed_keys = %w[
      email strip_exif show_community_spotlight_in_stream language auto_follow_back_aspect disable_mail auto_follow_back
    ]
    data = convert_keys(archive_hash["user"], allowed_keys)
    new_password = SecureRandom.hex
    data.merge!(
      username:              username,
      password:              new_password,
      password_confirmation: new_password
    )
    data[:email] = email if email.present?
    self.user = User.build(data)
    user.save!
  end

  private

  attr_reader :archive_hash

  def import_contacts
    import_collection(contacts, ContactImporter)
  end

  def import_aspects
    contact_groups.each do |group|
      begin
        user.aspects.create!(group.slice("name", "chat_enabled", "contacts_visible"))
      rescue ActiveRecord::RecordInvalid => e
        logger.warn "#{self}: #{e}"
      end
    end
  end

  def import_posts
    import_collection(posts, PostImporter)
  end

  def import_relayables
    import_collection(relayables, OwnRelayableImporter)
  end

  def import_others_relayables
    import_collection(others_relayables, EntityImporter)
  end

  def import_collection(collection, importer_class)
    collection.each do |object|
      importer_class.new(object, user).import
    end
  end

  def import_tag_followings
    archive_hash.fetch("user").fetch("followed_tags", []).each do |tag_name|
      begin
        tag = ActsAsTaggableOn::Tag.find_or_create_by(name: tag_name)
        user.tag_followings.create!(tag: tag)
      rescue ActiveRecord::RecordInvalid
      end
    end
  end

  def import_subscriptions
    post_subscriptions.each do |post_guid|
      post = Post.find_or_fetch_by(archive_author_diaspora_id, post_guid)
      if post.nil?
        logger.warn "#{self}: post with guid #{post_guid} not found, can't subscribe"
        next
      end
      begin
        user.participations.create!(target: post)
      rescue ActiveRecord::RecordInvalid
      end
    end
  end

  def convert_keys(hash, allowed_keys)
    hash
      .slice(*allowed_keys)
      .symbolize_keys
  end

  def to_s
    "#{self.class}:#{archive_author_diaspora_id}:#{user.diaspora_handle}"
  end
end
