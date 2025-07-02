# app/services/youtube_services/manager.rb
module YoutubeServices
  class Manager
    def initialize(access_token)
      @access_token = access_token
    end

    def video_service
      @video_service ||= VideoService.new(@access_token)
    end

    def playlist_service
      @playlist_service ||= PlaylistService.new(@access_token)
    end

    # Delegate methods for easier access
    delegate :upload_video, :set_thumbnail, :set_privacy, :list_uploaded_videos, :get_video_details, to: :video_service
    delegate :create_playlist, :delete_playlist, :update_playlist, :add_video_to_playlist,
             :remove_video_from_playlist, :reorder_playlist_item, :list_playlist_items,
             :list_playlists, :get_playlist_details, to: :playlist_service
  end
end
