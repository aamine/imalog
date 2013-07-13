class CreateMarkupSyntaxes < ActiveRecord::Migration
  def change
    create_table :markup_syntaxes do |t|
      t.text :name
      t.text :class_name
      t.timestamps
    end
  end
end
