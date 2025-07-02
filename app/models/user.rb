# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
      user.youtube_token = auth.credentials.token
      user.refresh_token = auth.credentials.refresh_token if auth.credentials.refresh_token
      user.password = Devise.friendly_token[0, 20]
    end
  end

  def update_youtube_tokens(auth)
    update!(
      youtube_token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token || refresh_token
    )
  end
end
