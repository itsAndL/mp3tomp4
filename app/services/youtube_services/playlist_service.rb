# app/services/youtube_services/playlist_service.rb
module YoutubeServices
  class PlaylistService < BaseService
    def create_playlist(title:, description: "", privacy_status: "public")
      handle_api_error do
        playlist_object = Google::Apis::YoutubeV3::Playlist.new(
          snippet: Google::Apis::YoutubeV3::PlaylistSnippet.new(
            title: title,
            description: description
          ),
          status: Google::Apis::YoutubeV3::PlaylistStatus.new(
            privacy_status: privacy_status
          )
        )

        result = @youtube.insert_playlist("snippet,status", playlist_object)

        {
          playlist_id: result.id,
          title: result.snippet.title,
          description: result.snippet.description,
          url: "https://www.youtube.com/playlist?list=#{result.id}"
        }
      end
    end

    def delete_playlist(playlist_id:)
      handle_api_error do
        @youtube.delete_playlist(playlist_id)
        { success: true, message: "Playlist deleted successfully" }
      end
    end

    def update_playlist(playlist_id:, title: nil, description: nil, privacy_status: nil)
      handle_api_error do
        # First get current playlist data
        current = @youtube.list_playlists("snippet,status", id: playlist_id).items.first
        return { error: "Playlist not found" } unless current

        playlist_object = Google::Apis::YoutubeV3::Playlist.new(
          id: playlist_id,
          snippet: Google::Apis::YoutubeV3::PlaylistSnippet.new(
            title: title || current.snippet.title,
            description: description || current.snippet.description
          ),
          status: Google::Apis::YoutubeV3::PlaylistStatus.new(
            privacy_status: privacy_status || current.status.privacy_status
          )
        )

        result = @youtube.update_playlist("snippet,status", playlist_object)

        {
          playlist_id: result.id,
          title: result.snippet.title,
          description: result.snippet.description,
          privacy_status: result.status.privacy_status,
          url: "https://www.youtube.com/playlist?list=#{result.id}"
        }
      end
    end

    def add_video_to_playlist(playlist_id:, video_id:)
      handle_api_error do
        playlist_item = Google::Apis::YoutubeV3::PlaylistItem.new(
          snippet: Google::Apis::YoutubeV3::PlaylistItemSnippet.new(
            playlist_id: playlist_id,
            resource_id: Google::Apis::YoutubeV3::ResourceId.new(
              kind: "youtube#video",
              video_id: video_id
            )
          )
        )

        result = @youtube.insert_playlist_item("snippet", playlist_item)

        {
          playlist_item_id: result.id,
          video_id: video_id,
          playlist_id: playlist_id,
          position: result.snippet.position
        }
      end
    end

    def remove_video_from_playlist(playlist_id:, video_id:)
      handle_api_error do
        # Find the playlist item
        items = list_playlist_items(playlist_id: playlist_id)
        item = items.find { |i| i[:video_id] == video_id }

        return { error: "Video not found in playlist" } unless item

        @youtube.delete_playlist_item(item[:playlist_item_id])
        { success: true, message: "Video removed from playlist" }
      end
    end

    def reorder_playlist_item(playlist_id:, video_id:, position:)
      handle_api_error do
        # Find the playlist item
        items = list_playlist_items(playlist_id: playlist_id)
        item = items.find { |i| i[:video_id] == video_id }

        return { error: "Video not found in playlist" } unless item

        playlist_item = Google::Apis::YoutubeV3::PlaylistItem.new(
          id: item[:playlist_item_id],
          snippet: Google::Apis::YoutubeV3::PlaylistItemSnippet.new(
            playlist_id: playlist_id,
            position: position,
            resource_id: Google::Apis::YoutubeV3::ResourceId.new(
              kind: "youtube#video",
              video_id: video_id
            )
          )
        )

        result = @youtube.update_playlist_item("snippet", playlist_item)

        {
          playlist_item_id: result.id,
          video_id: video_id,
          new_position: result.snippet.position
        }
      end
    end

    def list_playlist_items(playlist_id:)
      handle_api_error do
        response = @youtube.list_playlist_items(
          "snippet",
          playlist_id: playlist_id,
          max_results: 50
        )

        response.items.map do |item|
          {
            playlist_item_id: item.id,
            video_id: item.snippet.resource_id.video_id,
            title: item.snippet.title,
            position: item.snippet.position,
            video_url: "https://www.youtube.com/watch?v=#{item.snippet.resource_id.video_id}"
          }
        end
      end
    end

    def list_playlists
      handle_api_error do
        response = @youtube.list_playlists(
          "snippet,status",
          mine: true,
          max_results: 50
        )

        response.items.map do |playlist|
          {
            playlist_id: playlist.id,
            title: playlist.snippet.title,
            description: playlist.snippet.description,
            privacy_status: playlist.status.privacy_status,
            item_count: playlist.content_details&.item_count || 0,
            url: "https://www.youtube.com/playlist?list=#{playlist.id}"
          }
        end
      end
    end

    def get_playlist_details(playlist_id:)
      handle_api_error do
        response = @youtube.list_playlists(
          "snippet,status,contentDetails",
          id: playlist_id
        )

        playlist = response.items.first
        return nil unless playlist

        {
          playlist_id: playlist.id,
          title: playlist.snippet.title,
          description: playlist.snippet.description,
          privacy_status: playlist.status.privacy_status,
          item_count: playlist.content_details.item_count,
          url: "https://www.youtube.com/playlist?list=#{playlist.id}"
        }
      end
    end
  end
end
