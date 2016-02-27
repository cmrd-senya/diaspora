module Export
  class ProfileSerializer < ActiveModel::Serializer
    attributes :first_name,
               :last_name,
               :gender,
               :bio,
               :birthday,
               :location,
               :image_url,
               :thefederation_uid,
               :searchable,
               :nsfw

    def thefederation_uid
      object.diaspora_handle
    end
  end
end
