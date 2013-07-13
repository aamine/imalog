class Blog < ActiveRecord::Base
  def Blog.instance
    @instance ||= all.first or raise 'FATAL: no blog exists'
  end

  belongs_to :user
  belongs_to :markup_syntax
end
