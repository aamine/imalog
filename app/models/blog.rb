class Blog < ActiveRecord::Base
  def Blog.instance
    # Only one instance should do exist.
    @instance ||= all.first or raise 'FATAL: no blog exists'
  end

  belongs_to :markup_syntax
end
