module Export
  class PostSerializer < ActiveModel::Serializer
    attributes :guid,
               :text,
               :public,
               :thefederation_uid,
               :type,
               :image_url,
               :image_height,
               :image_width,
               :likes_count,
               :comments_count,
               :reshares_count,
               :created_at

    def thefederation_uid
      object.diaspora_handle
    end
  end
end
