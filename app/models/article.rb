class Article < ActiveRecord::Base
  scope :latests, order('created_at desc').limit(5)

  belongs_to :blog
  belongs_to :markup_syntax

  before_save :set_markup_syntax

  def set_markup_syntax
    self.markup_syntax ||= blog.markup_syntax
  end
  private :set_markup_syntax

  def compile
    markup_syntax.compile(body)
  end
end
