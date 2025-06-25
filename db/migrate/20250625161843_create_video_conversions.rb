class CreateVideoConversions < ActiveRecord::Migration[8.0]
  def change
    create_table :video_conversions do |t|
      t.string :title
      t.text :description
      t.integer :status
      t.integer :progress

      t.timestamps
    end
  end
end
