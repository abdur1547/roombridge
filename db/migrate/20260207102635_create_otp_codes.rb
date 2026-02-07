class CreateOtpCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :otp_codes do |t|
      t.string :phone_number, null: false, default: ""
      t.string :code, null: false, default: ""
      t.datetime :expires_at, null: false
      t.datetime :consumed_at, null: true

      t.timestamps
    end
    add_index :otp_codes, :phone_number, unique: true
  end
end
