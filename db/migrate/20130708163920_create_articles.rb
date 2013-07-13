class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.integer :blog_id
      t.text :title
      t.text :body
      t.integer :markup_syntax_id
      t.timestamps
    end
    add_index :articles, :created_at
  end
end
