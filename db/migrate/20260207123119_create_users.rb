class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :phone_number, null: false, default: ""

      t.integer :admin_verification_status, null: false, default: 0

      t.string  :full_name, null: true
      t.string  :cnic_hash, null: true
      t.integer :gender, null: true
      t.integer :role, null: false, default: 0

      t.timestamps
    end

    add_index :users, :phone_number, unique: true
    add_index :users, :cnic_hash, unique: true, where: "cnic_hash IS NOT NULL"
    add_column :users, :profile_picture_data, :text
    add_column :users, :verification_selfie_data, :text
    add_column :users, :cnic_images_data, :text
  end
end
