class AddAttachmentsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :profile_picture_data, :text
    add_column :users, :verification_selfie_data, :text
    add_column :users, :cnic_images_data, :text
  end
end
