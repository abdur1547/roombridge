class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties, id: :uuid do |t|
      t.integer :property_type, null: false, default: 0
      t.string :city, null: false, default: ""
      t.string :area, null: false, default: ""
      t.text :address, null: false, default: ""
      t.integer :total_bedrooms, null: false, default: 0
      t.integer :total_bathrooms, null: false, default: 0
      t.boolean :parking, null: false, default: false
      t.integer :gender_preference, null: false, default: 0
      t.boolean :only_verified_users, null: false, default: false
      t.boolean :elevator, null: false, default: false
      t.references :owner, null: false, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end
  end
end
