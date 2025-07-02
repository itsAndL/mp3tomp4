# app/services/youtube_services/base_service.rb
require "google/apis/youtube_v3"
require "googleauth"

module YoutubeServices
  class BaseService
    def initialize(access_token)
      @access_token = access_token
      @youtube = Google::Apis::YoutubeV3::YouTubeService.new
      @youtube.authorization = build_authorization
    end

    private

    def build_authorization
      auth = Google::Auth::UserRefreshCredentials.new(
        client_id: ENV["YOUTUBE_CLIENT_ID"],
        client_secret: ENV["YOUTUBE_CLIENT_SECRET"],
        scope: [ "https://www.googleapis.com/auth/youtube" ],
        access_token: @access_token
      )
      auth
    end

    def handle_api_error
      yield
    rescue Google::Apis::Error => e
      Rails.logger.error "YouTube API Error: #{e.message}"
      raise YoutubeServices::AuthenticationError, "YouTube API Error: #{e.message}"
    end
  end
end
