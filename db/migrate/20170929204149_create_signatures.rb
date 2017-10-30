class CreateSignatures < ActiveRecord::Migration[5.1]
  def change
    create_table :signatures do |t|
      t.text :body, null: false
    end

    add_column :account_migrations, :signature_id, :integer
  end
end
