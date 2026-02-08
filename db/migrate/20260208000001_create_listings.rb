class CreateListings < ActiveRecord::Migration[7.2]
  def change
    create_table :listings, id: :uuid do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, type: :uuid

      # Location
      t.string :city, null: false
      t.string :area, null: false

      # Room & occupancy
      t.integer :room_type, null: false
      t.integer :max_occupants, null: false

      # Pricing
      t.integer :rent_monthly, null: false
      t.integer :deposit

      # Availability
      t.date :available_from, null: false
      t.integer :minimum_stay_months, null: false, default: 1

      # Preferences
      t.integer :gender_preference, null: false
      t.boolean :furnished, null: false, default: false

      # Rules
      t.boolean :smoking_allowed, null: false, default: false

      # Status
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_column :listings, :photos_data, :text

    add_index :listings, [ :city, :area ]
    add_index :listings, :is_active

    # # Add check constraints
    # execute <<-SQL
    #   ALTER TABLE listings ADD CONSTRAINT check_max_occupants_positive#{' '}
    #   CHECK (max_occupants > 0);
    # SQL

    # execute <<-SQL
    #   ALTER TABLE listings ADD CONSTRAINT check_rent_monthly_positive#{' '}
    #   CHECK (rent_monthly > 0);
    # SQL

    # execute <<-SQL
    #   ALTER TABLE listings ADD CONSTRAINT check_deposit_non_negative#{' '}
    #   CHECK (deposit IS NULL OR deposit >= 0);
    # SQL

    # execute <<-SQL
    #   ALTER TABLE listings ADD CONSTRAINT check_minimum_stay_months_positive#{' '}
    #   CHECK (minimum_stay_months > 0);
    # SQL
  end
end
