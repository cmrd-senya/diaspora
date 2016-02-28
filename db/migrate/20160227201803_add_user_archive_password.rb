class AddUserArchivePassword < ActiveRecord::Migration
  def change
    add_column :users, :archive_password, :string
  end
end
