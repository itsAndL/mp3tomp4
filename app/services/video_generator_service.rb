class VideoGeneratorService
  attr_reader :title, :description, :audio_file, :logo_file, :temp_dir

  def initialize(title:, description: nil, audio_file:, logo_file:)
    @title = title
    @description = description
    @audio_file = audio_file
    @logo_file = logo_file
    @temp_dir = nil
  end

  def call
    setup_temp_directory

    begin
      # Copy files to temp location
      mp3_path = copy_file_to_temp(audio_file, "audio.mp3")
      logo_path = copy_file_to_temp(logo_file, "logo.png")

      # Create background image with text
      background_path = create_background_image(logo_path, temp_dir.join("background.png"))

      # Generate video
      output_path = temp_dir.join("output.mp4")
      generate_video(mp3_path, background_path, output_path)

      # Return the generated video file
      {
        success: true,
        video_path: output_path.to_s,
        filename: "#{title.parameterize}.mp4"
      }
    rescue => e
      Rails.logger.error "Video generation failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      {
        success: false,
        error: e.message
      }
    ensure
      # Note: Don't clean up temp files here since caller might need the video
      # Caller should handle cleanup
    end
  end

  def cleanup!
    FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exist?(temp_dir)
  end

  private

  def setup_temp_directory
    @temp_dir = Rails.root.join("tmp", "video_generation", SecureRandom.uuid)
    FileUtils.mkdir_p(@temp_dir)
  end

  def copy_file_to_temp(file, filename)
    temp_path = temp_dir.join(filename)

    if file.respond_to?(:download)
      # Handle Active Storage attachment
      File.open(temp_path, "wb") do |temp_file|
        file.download { |chunk| temp_file.write(chunk) }
      end
    elsif file.respond_to?(:read)
      # Handle uploaded file or IO object
      File.open(temp_path, "wb") do |temp_file|
        file.rewind if file.respond_to?(:rewind)
        temp_file.write(file.read)
      end
    elsif file.is_a?(String) && File.exist?(file)
      # Handle file path
      FileUtils.cp(file, temp_path)
    else
      raise ArgumentError, "Unsupported file type: #{file.class}"
    end

    temp_path.to_s
  end

  def create_background_image(logo_path, output_path)
    require "mini_magick"

    MiniMagick::Tool::Convert.new do |convert|
      convert << "-size" << "1920x1080"
      convert << "canvas:#1a1a1a"  # Dark background

      # Add logo (resize to fit)
      convert << "("
      convert << logo_path
      convert << "-resize" << "600x600>"
      convert << "-gravity" << "center"
      convert << "-geometry" << "+0-200"
      convert << ")"
      convert << "-composite"

      # Add title
      convert << "-font" << "Arial"
      convert << "-fill" << "white"
      convert << "-pointsize" << "72"
      convert << "-gravity" << "center"
      convert << "-annotate" << "+0+150" << title

      # Add description (if present)
      if description.present?
        convert << "-font" << "Arial"
        convert << "-fill" << "#cccccc"
        convert << "-pointsize" << "36"
        convert << "-gravity" << "center"
        convert << "-annotate" << "+0+300" << word_wrap(description, 40)
      end

      convert << output_path.to_s
    end

    output_path.to_s
  end

  def generate_video(mp3_path, background_path, output_path)
    require "streamio-ffmpeg"

    # Get audio duration
    audio = FFMPEG::Movie.new(mp3_path)
    duration = audio.duration

    # FFmpeg command to create video
    ffmpeg_command = [
      "ffmpeg",
      "-loop", "1",
      "-i", background_path,
      "-i", mp3_path,
      "-c:v", "libx264",
      "-tune", "stillimage",
      "-c:a", "aac",
      "-b:a", "192k",
      "-pix_fmt", "yuv420p",
      "-shortest",
      "-t", duration.to_s,
      "-y",
      output_path.to_s
    ]

    # Execute FFmpeg
    Open3.popen3(*ffmpeg_command) do |stdin, stdout, stderr, thread|
      unless thread.value.success?
        error_output = stderr.read
        raise "FFmpeg failed: #{error_output}"
      end
    end
  end

  def word_wrap(text, max_chars)
    text.scan(/.{1,#{max_chars}}(?:\s|$)/).join("\n")
  end
end
