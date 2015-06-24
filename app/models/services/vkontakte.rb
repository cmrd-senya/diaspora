class Services::Vkontakte < Service
  include Rails.application.routes.url_helpers

  MAX_CHARACTERS = 63206

  def provider
    "vkontakte"
  end

  def post(post, url='')
    logger.debug "event=post_to_service type=vkontakte sender_id=#{user_id} post=#{post.guid}"
    VkontakteApi.configure do |config|
      config.api_version = '5.21'
      config.app_id       = AppConfig.services.vkontakte.app_id
      config.app_secret   = AppConfig.services.vkontakte.app_secret
    end
    @vk = VkontakteApi::Client.new(access_token)
    post.vk_id = @vk.wall.post(message: post.message.plain_text_without_markdown).post_id
    post.save
  end

end
