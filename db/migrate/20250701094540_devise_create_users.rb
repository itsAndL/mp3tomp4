# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      # Add YouTube OAuth fields
      t.string :provider
      t.string :uid
      t.string :name
      t.text :youtube_token
      t.text :refresh_token

      # Devise modules
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, [ :provider, :uid ],     unique: true
  end
end
