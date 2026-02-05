class AddOtpFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :otp_code, :string
    add_column :users, :otp_expires_at, :datetime
    add_column :users, :otp_attempts, :integer, default: 0
    add_column :users, :otp_verified, :boolean, default: false
    add_column :users, :last_otp_sent_at, :datetime

    add_index :users, :otp_code
    add_index :users, :otp_expires_at
    add_index :users, :otp_verified
  end
end
