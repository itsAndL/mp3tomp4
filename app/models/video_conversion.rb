class VideoConversion < ApplicationRecord
  has_one_attached :mp3_file
  has_one_attached :logo_image
  has_one_attached :output_video

  validates :title, presence: true
  validates :mp3_file, presence: true
  validates :logo_image, presence: true

  enum :status, %i[pending processing completed failed]

  after_create_commit :process_video_later

  private

  def process_video_later
    VideoProcessingJob.perform_later(self)
  end
end
