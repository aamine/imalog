class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.integer :blog_id
      t.text :title
      t.text :body
      t.integer :markup_syntax_id
      t.timestamps
    end
  end
end
