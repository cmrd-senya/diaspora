#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class ContactsController < ApplicationController
  before_action :authenticate_user!

  def index
    respond_to do |format|

      # Used for normal requests to contacts#index
      format.html { set_up_contacts }

      # Used by the mobile site
      format.mobile { set_up_contacts_mobile }

      # Used for mentions in the publisher
      format.json {
        @people = if params[:q].present?
                    Person.search(params[:q], current_user, only_contacts: true).limit(15)
                  else
                    set_up_contacts_json
                  end
        render json: @people
      }
    end
  end

  def spotlight
    @spotlight = true
    @people = Person.community_spotlight
  end

  private

  def set_up_contacts
    type = params[:set].presence
    if params[:a_id].present?
      type ||= "by_aspect"
      @aspect = current_user.aspects.find(params[:a_id])
      gon.preloads[:aspect] = AspectPresenter.new(@aspect).as_json
    end
    type ||= "receiving"
    @contacts_size = contacts_by_type(type).length
  end

  def set_up_contacts_json
    type = params[:set].presence
    if params[:a_id].present?
      type ||= "by_aspect"
      @aspect = current_user.aspects.find(params[:a_id])
    end
    type ||= "receiving"
    contacts_by_type(type).paginate(page: params[:page], per_page: 25)
                          .map {|c| ContactPresenter.new(c, current_user).full_hash_with_person }
  end

  def contacts_by_type(type)
    order = ["profiles.first_name ASC", "profiles.last_name ASC", "profiles.diaspora_handle ASC"]
    contacts = case type
      when "all"
        order.unshift "receiving DESC"
        current_user.contacts
      when "only_sharing"
        current_user.contacts.only_sharing
      when "receiving"
        current_user.contacts.receiving
      when "by_aspect"
        order.unshift "contact_id IS NOT NULL DESC"
        current_user.contacts.joins(
          "LEFT OUTER JOIN aspect_memberships ON contacts.id = contact_id"
        ).where(aspect_memberships: {aspect_id: [nil, params[:a_id]]})
      else
        raise ArgumentError, "unknown type #{type}"
      end
    contacts.includes(person: :profile)
            .order(order)
  end

  def set_up_contacts_mobile
    @contacts = case params[:set]
      when "only_sharing"
        current_user.contacts.only_sharing
      when "all"
        current_user.contacts
      else
        if params[:a_id]
          @aspect = current_user.aspects.find(params[:a_id])
          @aspect.contacts
        else
          current_user.contacts.receiving
        end
    end
    @contacts = @contacts.for_a_stream.paginate(:page => params[:page], :per_page => 25)
    @contacts_size = @contacts.length
  end
end
