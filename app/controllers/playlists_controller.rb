# app/controllers/playlists_controller.rb
class PlaylistsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_playlist_id, only: [ :show, :edit, :update, :destroy, :add_video, :remove_video, :reorder_video ]

  def index
    @playlists = youtube_manager.list_playlists
  end

  def show
    @playlist = youtube_manager.get_playlist_details(playlist_id: @playlist_id)
    @items = youtube_manager.list_playlist_items(playlist_id: @playlist_id)
    @videos = youtube_manager.list_uploaded_videos
  end

  def new
    # Form for creating new playlist
  end

  def create
    result = youtube_manager.create_playlist(
      title: params[:title],
      description: params[:description],
      privacy_status: params[:privacy_status]
    )
    redirect_to playlist_path(result[:playlist_id]), notice: "Playlist created successfully!"
  rescue YoutubeServices::AuthenticationError => e
    redirect_to playlists_path, alert: "Creation failed: #{e.message}"
  end

  def edit
    @playlist = youtube_manager.get_playlist_details(playlist_id: @playlist_id)
  end

  def update
    youtube_manager.update_playlist(
      playlist_id: @playlist_id,
      title: params[:title],
      description: params[:description],
      privacy_status: params[:privacy_status]
    )
    redirect_to playlist_path(@playlist_id), notice: "Playlist updated successfully!"
  rescue YoutubeServices::AuthenticationError => e
    redirect_to playlist_path(@playlist_id), alert: "Update failed: #{e.message}"
  end

  def destroy
    youtube_manager.delete_playlist(playlist_id: @playlist_id)
    redirect_to playlists_path, notice: "Playlist deleted successfully!"
  rescue YoutubeServices::AuthenticationError => e
    redirect_to playlists_path, alert: "Deletion failed: #{e.message}"
  end

  def add_video
    youtube_manager.add_video_to_playlist(
      playlist_id: @playlist_id,
      video_id: params[:video_id]
    )
    redirect_to playlist_path(@playlist_id), notice: "Video added to playlist!"
  rescue YoutubeServices::AuthenticationError => e
    redirect_to playlist_path(@playlist_id), alert: "Failed to add video: #{e.message}"
  end

  def remove_video
    youtube_manager.remove_video_from_playlist(
      playlist_id: @playlist_id,
      video_id: params[:video_id]
    )
    redirect_to playlist_path(@playlist_id), notice: "Video removed from playlist!"
  rescue YoutubeServices::AuthenticationError => e
    redirect_to playlist_path(@playlist_id), alert: "Failed to remove video: #{e.message}"
  end

  def reorder_video
  end

  private

  def set_playlist_id
    @playlist_id = params[:id]
  end
end
