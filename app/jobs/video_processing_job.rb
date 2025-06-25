class VideoProcessingJob < ApplicationJob
  queue_as :default

  def perform(video_conversion)
    video_conversion.update!(status: "processing", progress: 0)

    service = VideoGeneratorService.new(
      title: video_conversion.title,
      description: video_conversion.description,
      audio_file: video_conversion.mp3_file,
      logo_file: video_conversion.logo_image
    )

    begin
      result = service.call

      if result[:success]
        # Attach the output video
        video_conversion.output_video.attach(
          io: File.open(result[:video_path]),
          filename: result[:filename],
          content_type: "video/mp4"
        )

        video_conversion.update!(status: "completed", progress: 100)
      else
        video_conversion.update!(status: "failed", progress: 0)
        raise StandardError, result[:error]
      end
    rescue => e
      Rails.logger.error "Video processing failed: #{e.message}"
      video_conversion.update!(status: "failed", progress: 0)
      raise e
    ensure
      # Clean up temp files
      service.cleanup!
    end
  end
end
