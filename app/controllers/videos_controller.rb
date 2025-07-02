# app/controllers/videos_controller.rb
class VideosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_video_id, only: [ :show, :set_privacy, :set_thumbnail ]

  def index
    @videos = youtube_manager.list_uploaded_videos
  rescue YoutubeServices::AuthenticationError => e
    redirect_to root_path, alert: "Authentication error: #{e.message}"
  end

  def show
    @video = youtube_manager.get_video_details(video_id: @video_id)
    @playlists = youtube_manager.list_playlists
  end

  def new
    # Form for uploading new video
  end

  def create
    if params[:video_file].present?
      uploaded_file = params[:video_file]

      result = youtube_manager.upload_video(
        title: params[:title],
        description: params[:description],
        file_source: uploaded_file.tempfile,
        privacy_status: params[:privacy_status]
      )

      redirect_to video_path(result[:video_id]), notice: "Video uploaded successfully!"
    else
      redirect_to new_video_path, alert: "Please select a video file"
    end
  end

  def set_privacy
    youtube_manager.set_privacy(video_id: @video_id, status: params[:status])
    redirect_to video_path(@video_id), notice: "Privacy setting updated!"
  rescue YoutubeServices::AuthenticationError => e
    redirect_to video_path(@video_id), alert: "Update failed: #{e.message}"
  end

  def set_thumbnail
    if params[:thumbnail].present?
      uploaded_file = params[:thumbnail]
      temp_path = Rails.root.join("tmp", uploaded_file.original_filename)

      File.open(temp_path, "wb") do |file|
        file.write(uploaded_file.read)
      end

      youtube_manager.set_thumbnail(video_id: @video_id, image_path: temp_path)
      File.delete(temp_path) if File.exist?(temp_path)

      redirect_to video_path(@video_id), notice: "Thumbnail updated!"
    end
  rescue YoutubeServices::AuthenticationError => e
    redirect_to video_path(@video_id), alert: "Thumbnail update failed: #{e.message}"
  end

  private

  def set_video_id
    @video_id = params[:id]
  end
end
