include WonderScript

module WonderScript
  module Analyzer
    include Util
  
    def analyze(form)
      form_ = WonderScript.macroexpand(form)
      form_.to_wonderscript_ast
    end
  
    def analyze_definition(form)
      Syntax::Definition.new(form[1].to_wonderscript_ast, form[2].to_wonderscript_ast)
    end
  
    def analyze_conditional(form)
      predicates = []
      default = nil
      body = form.rest
      raise 'cond body should have an even number of elements' unless body.size % 2 == 0
      i = 0
      while i < body.size
        if body[i] == :else
          default = body[i + 1].to_wonderscript_ast
          if default.is_a? Syntax::TailCall
            default.flag_as_tailcall!
          end
        else
          alt = body[i + 1].to_wonderscript_ast
          if alt.is_a? Syntax::TailCall
            alt.flag_as_tailcall!
          end
          predicates.push([
            body[i].to_wonderscript_ast,
            alt
          ])
        end
        i += 2
      end
      Syntax::Conditional.new(predicates, default)
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
      Syntax::MacroDefinition.new(
        form[1].to_wonderscript_ast,
        Syntax::Lambda.new(form[2].map(&:to_wonderscript_ast), form.rest.rest.rest.map(&:to_wonderscript_ast)))
    end
  
    def analyze_lambda(form)
      if form[1].is_a? EDN::Type::List
        # (fn
        #   ([] 0)
        #   ([x] x)
        #   ([x y] (+ x y)))
        arglist = form.rest.map { |x| x[0].map(&:to_wonderscript_ast) }
        bodies  = form.rest.map { |x| Syntax::Block.new(x[1].map(&:to_wonderscript_ast)) }
        Syntax::Lambda.new(arglist, bodies)
      elsif form[1].is_a? Array
        Syntax::Lambda.new(
          form[1].map(&:to_wonderscript_ast),
          Syntax::Block.new(form.rest.rest.map(&:to_wonderscript_ast)))
      else
        raise 'second element of a function expression must be a vector or a list'
      end
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

    def analyze_type_definition(form)
      raise 'second element of a type definition should be a symbol' unless form[1].is_a? EDN::Type::Symbol
      raise 'third element of a type definition should be a vector' unless form[2].is_a? Array
      specs = form.rest.rest.rest
      protos = specs.select { |x| x.is_a? EDN::Type::Symbol }.map(&:to_wonderscript_ast)
      methods = specs.select { |x| x.is_a? EDN::Type::List }.map do |meth|
        Syntax::TypeMethod.new(
          meth[0].to_wonderscript_ast,
          meth[1].map(&:to_wonderscript_ast),
          Syntax::Block.new(meth.rest.rest.map(&:to_wonderscript_ast)))
      end
      # TODO: TypeMethods need to have a reference of the type that they are a part of
      Syntax::Definition.new(
        form[1].to_wonderscript_ast,
        Syntax::TypeDefinition.new(form[2].map(&:to_wonderscript_ast), protos, methods))
    end

    def analyze_protocol_definition(form)
      raise 'second element of a type definition should be a symbol' unless form[1].is_a? EDN::Type::Symbol
      specs = form.rest.rest
      protos = specs.select { |x| x.is_a? EDN::Type::Symbol }.map(&:to_wonderscript_ast)
      methods = specs.select { |x| x.is_a? EDN::Type::List }.map do |meth|
        Syntax::TypeMethod.new(
          meth[0].to_wonderscript_ast,
          meth[1].map(&:to_wonderscript_ast),
          Syntax::Block.new(meth.rest.rest.map(&:to_wonderscript_ast)))
      end
      Syntax::ProtocolDefinition.new(form[1].to_wonderscript_ast, protos, methods)
    end
  
    def analyze_assignment(form)
      Syntax::Assignment.new(form[1].to_wonderscript_ast, form[2].to_wonderscript_ast)
    end
  
    def analyze_exception_handler(form)
      Syntax::ExceptionHandler.new(form[1].to_wonderscript_ast, form[2].to_wonderscript_ast, form[3].to_wonderscript_ast)
    end
  
    def analyze_exception(form)
      Syntax::Exception.new(form[1].to_wonderscript_ast)
    end
  
    def analyze_loop(form)
      raise 'loop bindings must be a vector' unless form[1].is_a? Array
      raise 'loop bindings should have an even numbe of elements' unless form[1].count % 2 == 0
      names  = []
      values = []
      i = 0
      while i < form[1].size
        names.push(form[1][i].to_wonderscript_ast)
        values.push(form[1][i + 1].to_wonderscript_ast)
        i += 2
      end
      Syntax::Loop.new(
        Syntax::Bindings.new(names, values),
        Syntax::Block.new(form.rest.rest.map(&:to_wonderscript_ast)))
    end

    def analyze_recursion_point(form)
      Syntax::RecursionPoint.new(form.rest.map(&:to_wonderscript_ast))
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
    form = self
    if first.is_a? EDN::Type::Symbol
      tag = first.to_sym
      case tag
      when :def         then analyze_definition(form)
      when :cond        then analyze_conditional(form)
      when :quote       then analyze_quote(form)
      when :defmacro    then analyze_macro_definition(form)
      when :fn          then analyze_lambda(form)
      when :'.'         then analyze_method_resolution(form)
      when :'.-'        then analyze_property_resolution(form)
      when :new         then analyze_class_instantiation(form)
      when :set!        then analyze_assignment(form)
      when :try         then analyze_exception_handler(form)
      when :loop        then analyze_loop(form)
      when :throw       then analyze_exception(form)
      when :recur       then analyze_recursion_point(form)
      when :deftype     then analyze_type_definition(form)
      when :defprotocol then analyze_protocol_definition(form)
      else
        if    binary_operator?     tag then analyze_binary_operator(form)
        elsif unary_operator?      tag then analyze_unary_operator(form)
        elsif arithmetic_operator? tag then analyze_arithmetic_operator(form)
        else
          analyze_application(form)
        end
      end
    else
      analyze_application(form)
    end
  end
end
