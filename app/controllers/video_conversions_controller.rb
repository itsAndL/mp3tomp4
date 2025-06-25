class VideoConversionsController < ApplicationController
  before_action :set_video_conversion, only: [ :show, :status ]

  def index
    @video_conversions = VideoConversion.order(created_at: :desc)
  end

  def new
    @video_conversion = VideoConversion.new
  end

  def create
    @video_conversion = VideoConversion.new(video_conversion_params)

    if @video_conversion.save
      redirect_to @video_conversion, notice: "Video conversion started!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def status
    render json: {
      status: @video_conversion.status,
      progress: @video_conversion.progress,
      download_url: @video_conversion.output_video.attached? ?
        rails_blob_url(@video_conversion.output_video) : nil
    }
  end

  private

  def set_video_conversion
    @video_conversion = VideoConversion.find(params[:id])
  end

  def video_conversion_params
    params.require(:video_conversion).permit(:title, :description, :mp3_file, :logo_image)
  end
end
