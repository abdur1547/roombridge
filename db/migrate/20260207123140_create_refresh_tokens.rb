class CreateRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :refresh_tokens, id: :uuid do |t|
      t.string :crypted_token
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.datetime :exp, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    add_index :refresh_tokens, :crypted_token, unique: true
  end
end
