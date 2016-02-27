module Export
  class ContactSerializer < ActiveModel::Serializer
    attributes :sharing,
               :following,
               :person_guid,
               :person_name,
               :person_first_name,
               :person_thefederation_uid

    has_many :contact_groups, each_serializer: Export::AspectSerializer

    def following
      object.receiving
    end

    def person_thefederation_uid
      object.person_diaspora_handle
    end

    def contact_groups
      object.aspects
    end
  end
end
