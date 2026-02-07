class CreateBlacklistedTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :blacklisted_tokens, id: :uuid do |t|
      t.string :jti
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.datetime :exp, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    add_index :blacklisted_tokens, :jti, unique: true
  end
end
