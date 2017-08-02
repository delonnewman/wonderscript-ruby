include WonderScript

module WonderScript::Analyzer
  def analyze(form)
    form.to_wonderscript_ast
  end

  def analyze_definition(form)
    Syntax::Definition.new(form[1].to_wonderscript_ast, form[2].to_wonderscript_ast)
  end

  def analyze_conditional(form)
    Syntax::Conditional.new(form[1].to_wonderscript_ast, form[2].to_wonderscript_ast, form[3].to_wonderscript_ast)
  end

  def analyze_quote(form)
    Syntax::Quote.new(self[1].to_wonderscript_ast)
  end

  def analyze_macro_definition(form)
    Syntax::MacroDefinition.new(form[1].to_wonderscript_ast, form[2].map(&:to_wonderscript_ast), form.rest.rest.map(&:to_wonderscript_ast))
  end

  def analyze_lambda(form)
    Syntax::Lambda.new(form[1].map(&:to_wonderscript_ast), form.rest.map(&:to_wonderscript_ast))
  end

  def analyze_method_resolution(form)
    Syntax::MethodResolution.new(form[1].to_wonderscript_ast, form[2].to_wonderscript_ast, form.rest.rest.map(&:to_wonderscript_ast))
  end

  def analyze_property_resolution(form)
    Syntax::PropertyResolution.new(form[1].to_wonderscript_ast, form[2].to_wonderscript_ast)
  end

  def analyze_class_instantiation(form)
    Syntax::ClassInstantiation.new(form[1].to_wonderscript_ast, form.rest.map(&:to_wonderscript_ast))
  end

  def analyze_assignment(form)
    Syntax::Assignment.new(form[1].to_wonderscript_ast, form[2].to_wonderscript_ast, form[3].to_wonderscript_ast)
  end

  def analyze_exception_handler(form)
    Syntax::ExceptionHandler.new(form[1].to_wonderscript_ast, form[2].to_wonderscript_ast, form[3].to_wonderscript_ast)
  end

  def analyze_loop(form)
    Syntax::Loop.new(form[1].to_wonderscript_ast, form.rest.map(&:to_wonderscript_ast))
  end

  def analyze_application(form)
    Syntax::Application.new(form[1].to_wonderscript_ast, form.rest.map(&:to_wonderscript_ast))
  end
end

class Object
  def to_wonderscript_ast
    Syntax::String.new(to_s)
  end
end

class Integer
  def to_wonderscript_ast
    Syntax::Integer.new(self)
  end
end

class Symbol
  def to_wonderscript_ast
    Syntax::Keyword.intern(self)
  end
end

class String
  def to_wonderscript_ast
    Syntax::String.new(self)
  end
end

class EDN::Type::Symbol
  def to_wonderscript_ast
    parts = to_s.split('/')
    ns, name =
      if parts.size === 1
        [nil, parts[0]]
      else
        parts
      end
    Syntax::Variable.new(ns, name)
  end
end

class FalseClass
  def to_wonderscript_ast
    Syntax::Boolean.intern(false)
  end
end

class TrueClass
  def to_wonderscript_ast
    Syntax::Boolean.intern(true)
  end
end

class NilClass
  def to_wonderscript_ast
    Syntax::Nil.intern
  end
end

class Array
  def to_wonderscript_ast
    Syntax::Vector.new(self.map(&:to_wonderscript_ast))
  end

  def rest
    slice(1, size) || []
  end
end

class Hash
  def to_wonderscript_ast
    Syntax::Map.new(self.map { |x| [x[0].to_wonderscript_ast, x[1].to_wonderscript_ast] })
  end
end

class Set
  def to_wonderscript_ast
    Syntax::Map.new(self.map(&:to_wonderscript_ast))
  end
end

class EDN::Type::List
  include WonderScript::Analyzer

  def to_wonderscript_ast
    tag = first
    case tag.to_sym
    when :def      then analyze_definition(self)
    when :if       then analyze_conditional(self)
    when :quote    then analyze_quote(self)
    when :defmacro then analyze_macro_definition(self)
    when :fn       then analyze_lambda(self)
    when :'.'      then analyze_method_resolution(self)
    when :new      then analyze_class_instantiation(self)
    when :set!     then analyze_assignment(self)
    when :try      then analyze_exception_handler(self)
    when :loop     then analyze_loop(self)
    else
      analyze_application(self)
    end
  end
end
