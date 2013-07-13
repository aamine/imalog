class MarkupSyntax < ActiveRecord::Base
  def compile(source)
    compiler.compile(source)
  end

  private

  def compiler
    @compiler ||= get_class(self.class_name).new
  end

  def get_class(path)
    path.split("::").inject(Object) {|base, name| base.const_get(name) }
  end
end
