class MarkupSyntax < ActiveRecord::Base
  def compile(source)
    compiler.compile(source)
  end

  private

  def compiler
    @compiler ||= get_compiler(self.class_name)
  end

  COMPILERS = {}

  def get_compiler(class_path)
    (COMPILERS[class_path] ||= load_compiler_class(class_path)).new
  end

  def load_compiler_class(class_path)
    require class_path.gsub('::', '/').downcase
    class_path.split("::").inject(Object) {|base, name| base.const_get(name) }
  end
end
