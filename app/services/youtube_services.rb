# app/services/youtube_services.rb
module YoutubeServices
  class AuthenticationError < StandardError; end
  class UploadError < StandardError; end
  class PlaylistError < StandardError; end
end
