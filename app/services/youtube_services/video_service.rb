# app/services/youtube_services/video_service.rb
module YoutubeServices
  class VideoService < BaseService
    def upload_video(title:, description:, file_source:, privacy_status: "public")
      handle_api_error do
        video_object = Google::Apis::YoutubeV3::Video.new(
          snippet: Google::Apis::YoutubeV3::VideoSnippet.new(
            title: title,
            description: description,
            category_id: "22"
          ),
          status: Google::Apis::YoutubeV3::VideoStatus.new(
            privacy_status: privacy_status
          )
        )

        result = @youtube.insert_video(
          "snippet,status",
          video_object,
          upload_source: file_source # This can now be an IO object or file path
        )

        {
          video_id: result.id,
          title: result.snippet.title,
          description: result.snippet.description,
          status: result.status.privacy_status,
          url: "https://www.youtube.com/watch?v=#{result.id}"
        }
      end
    end

    def set_thumbnail(video_id:, image_path:)
      handle_api_error do
        @youtube.set_video_thumbnail(
          video_id,
          upload_source: image_path
        )
        { success: true, message: "Thumbnail updated successfully" }
      end
    end

    def set_privacy(video_id:, status:)
      valid_statuses = %w[public private unlisted]
      raise ArgumentError, "Invalid status. Must be one of: #{valid_statuses.join(', ')}" unless valid_statuses.include?(status)

      handle_api_error do
        video_object = Google::Apis::YoutubeV3::Video.new(
          id: video_id,
          status: Google::Apis::YoutubeV3::VideoStatus.new(
            privacy_status: status
          )
        )

        @youtube.update_video("status", video_object)
        { success: true, status: status }
      end
    end

    def list_uploaded_videos(max_results: 50)
      handle_api_error do
        # First, get the authenticated user's channel
        channels_response = @youtube.list_channels(
          "contentDetails",
          mine: true
        )

        channel = channels_response.items.first
        return [] unless channel

        # Get the uploads playlist ID
        uploads_playlist_id = channel.content_details.related_playlists.uploads

        # Now fetch videos from the uploads playlist
        playlist_response = @youtube.list_playlist_items(
          "snippet",
          playlist_id: uploads_playlist_id,
          max_results: max_results
        )

        # Get video IDs
        video_ids = playlist_response.items.map { |item| item.snippet.resource_id.video_id }

        # Fetch video details including status for all videos at once
        videos_response = @youtube.list_videos(
          "snippet,status",
          id: video_ids.join(",")
        )

        # Create a hash for quick lookup of video details
        video_details = videos_response.items.each_with_object({}) do |video, hash|
          hash[video.id] = video
        end

        playlist_response.items.map do |item|
          video_id = item.snippet.resource_id.video_id
          video = video_details[video_id]

          {
            video_id: video_id,
            title: item.snippet.title,
            description: item.snippet.description,
            published_at: item.snippet.published_at,
            thumbnail_url: item.snippet.thumbnails.default.url,
            position: item.snippet.position,
            privacy_status: video&.status&.privacy_status || "unknown",
            url: "https://www.youtube.com/watch?v=#{video_id}"
          }
        end
      end
    end

    def get_video_details(video_id:)
      handle_api_error do
        response = @youtube.list_videos(
          "snippet,status,statistics",
          id: video_id
        )

        video = response.items.first
        return nil unless video

        {
          video_id: video.id,
          title: video.snippet.title,
          description: video.snippet.description,
          published_at: video.snippet.published_at,
          privacy_status: video.status.privacy_status,
          view_count: video.statistics&.view_count,
          like_count: video.statistics&.like_count,
          url: "https://www.youtube.com/watch?v=#{video.id}"
        }
      end
    end
  end
end
