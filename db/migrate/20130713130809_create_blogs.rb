class CreateBlogs < ActiveRecord::Migration
  def change
    create_table :blogs do |t|
      t.integer :user_id
      t.string :name
      t.integer :markup_syntax_id
      t.timestamps
    end
  end
end
