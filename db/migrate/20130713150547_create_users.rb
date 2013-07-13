class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.text :name
      t.text :profile
      t.text :email
      t.text :password_digest
      t.timestamps
    end
  end
end
