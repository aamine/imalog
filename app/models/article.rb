class Article < ActiveRecord::Base
  ##
  # articles newer than +origin+.
  # Articles are splitted into two groups, latest +n+ articles and older ones.
  def Article.latests(origin, n)
    list = where('created_at > ?', origin).order('created_at desc')
    return list[0, n], (list[n..-1] || [])
  end

  def Article.calendar_groups
  end

  belongs_to :blog
  belongs_to :markup_syntax

  before_save :set_markup_syntax

  def set_markup_syntax
    self.markup_syntax ||= blog.markup_syntax
  end
  private :set_markup_syntax

  validates_presence_of :title

  def compile
    markup_syntax.compile(body)
  end
end
