include WonderScript

module WonderScript::Analyzer
  include WonderScript::Util

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
    value =
      if form[1].is_a? EDN::Type::Symbol
        parts = form[1].to_s.split('/')
        ns, name =
          if parts.size === 1
            [nil, parts[0]]
          else
            parts
          end
        Syntax::Symbol.intern(ns, name)
      elsif form[1].is_a? EDN::Type::List
        Syntax::List.new(form[1].map(&:to_wonderscript_ast))
      else
        form[1].to_wonderscript_ast
      end
    Syntax::Quote.new(value)
  end

  def analyze_macro_definition(form)
    Syntax::MacroDefinition.new(form[1].to_wonderscript_ast, form[2].map(&:to_wonderscript_ast), form.rest.rest.map(&:to_wonderscript_ast))
  end

  def analyze_lambda(form)
    Syntax::Lambda.new(form[1].map(&:to_wonderscript_ast), form.rest.rest.map(&:to_wonderscript_ast))
  end

  def analyze_method_resolution(form)
    raise 'method resolution should be a list of 3 elements' unless form.size === 3
    method, args =
      if form[2].is_a? EDN::Type::Symbol
        [form[2], []]
      elsif form[2].is_a? EDN::Type::List
        [form[2].first, form[2].rest]
      end
    Syntax::MethodResolution.new(form[1].to_wonderscript_ast, method.to_wonderscript_ast, args.map(&:to_wonderscript_ast))
  end

  def analyze_property_resolution(form)
    Syntax::PropertyResolution.new(form[1].to_wonderscript_ast, form[2].to_wonderscript_ast)
  end

  def analyze_class_instantiation(form)
    Syntax::ClassInstantiation.new(form[1].to_wonderscript_ast, form.rest.rest.map(&:to_wonderscript_ast))
  end

  def analyze_assignment(form)
    Syntax::Assignment.new(form[1].to_wonderscript_ast, form[2].to_wonderscript_ast)
  end

  def analyze_exception_handler(form)
    Syntax::ExceptionHandler.new(form[1].to_wonderscript_ast, form[2].to_wonderscript_ast, form[3].to_wonderscript_ast)
  end

  def analyze_loop(form)
    Syntax::Loop.new(form[1].to_wonderscript_ast, form.rest.map(&:to_wonderscript_ast))
  end

  def analyze_application(form)
    Syntax::Application.new(form[0].to_wonderscript_ast, form.rest.map(&:to_wonderscript_ast))
  end

  def analyze_arithmetic_operator(form)
    op = ARITHMETIC_OPERATORS[form[0].to_sym] or raise "invalid arithmetic operator: #{form[0].inspect}"
    Syntax::ArithmeticOperator.new(Syntax::Variable.new(nil, op.to_s), form.rest.map(&:to_wonderscript_ast))
  end

  def analyze_binary_operator(form)
    argc = form.rest.size
    raise "wrong number of arguments, got: #{argc}, expected: 2, in: #{form.inspect}" unless argc == 2
    op = BINARY_OPERATORS[form[0].to_sym] or raise "invalid binary operator: #{form[0].inspect}"
    Syntax::BinaryOperator.new(Syntax::Variable.new(nil, op.to_s), form[1].to_wonderscript_ast, form[2].to_wonderscript_ast)
  end

  def analyze_unary_operator(form)
    argc = form.rest.size
    raise "wrong numer of arguments, got: #{argc}, expected: 1" unless argc == 1
    op = UNARY_OPERATORS[form[0].to_sym] or raise "invalid unary operator: #{form[0].inspect}"
    Syntax::UnaryOperator.new(Syntax::Variable.new(nil, op.to_s), form[1].to_wonderscript_ast)
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
    ns, name = WonderScript::Util.parse_symbol(self)
    Syntax::Keyword.intern(ns, name)
  end
end

class String
  def to_wonderscript_ast
    Syntax::String.new(self)
  end
end

class EDN::Type::Symbol
  def to_wonderscript_ast
    ns, name = WonderScript::Util.parse_symbol(self)
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
    drop(1)
  end
end

class Hash
  def to_wonderscript_ast
    Syntax::Map.new(self.map { |x| [x[0].to_wonderscript_ast, x[1].to_wonderscript_ast] })
  end
end

class Set
  def to_wonderscript_ast
    Syntax::Set.new(self.map(&:to_wonderscript_ast))
  end
end

class EDN::Type::List
  include WonderScript::Analyzer

  def to_wonderscript_ast
    if first.is_a? EDN::Type::Symbol
      tag = first.to_sym
      case tag
      when :def      then analyze_definition(self)
      when :if       then analyze_conditional(self)
      when :quote    then analyze_quote(self)
      when :defmacro then analyze_macro_definition(self)
      when :fn       then analyze_lambda(self)
      when :'.'      then analyze_method_resolution(self)
      when :'.-'     then analyze_property_resolution(self)
      when :new      then analyze_class_instantiation(self)
      when :set!     then analyze_assignment(self)
      when :try      then analyze_exception_handler(self)
      when :loop     then analyze_loop(self)
      else
        if    binary_operator?     tag then analyze_binary_operator(self)
        elsif unary_operator?      tag then analyze_unary_operator(self)
        elsif arithmetic_operator? tag then analyze_arithmetic_operator(self)
        else
          analyze_application(self)
        end
      end
    else
      analyze_application(self)
    end
  end
end
