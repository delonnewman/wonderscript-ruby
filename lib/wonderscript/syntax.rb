module WonderScript
  module Syntax
    class Syntax; end
    class Literal < Syntax; end
    class Atom < Literal
      def initialize(value)
        @value = value
      end
  
      def value
        @value
      end
    end
  
    module Interned; end
  
    class Nil < Atom
      include Interned
  
      def self.intern(value=nil)
        @instance ||= new(nil)
      end
    end
  
    class Boolean < Atom
      include Interned
  
      def self.intern(value)
        if value == false
          @false ||= new(value)
        else
          @true ||= new(value)
        end
      end
    end
  
    class Number < Atom
    end
  
    class Integer < Number
    end
  
    class Rational < Number
    end
  
    class Decimal < Number
    end
  
    class Keyword < Atom
      include Interned
  
      attr_reader :namespace, :name
  
      def self.intern(ns, name)
        @values ||= {}
        @values[:"#{ns}/#{name}"] ||= new(ns, name)
      end
  
      def initialize(ns, name)
        @namespace = ns
        @name      = name
      end
    end
  
    class String < Atom
      include Interned
  
      def self.intern(value)
        @values ||= {}
        @values[value] ||= new(value)
      end
    end
  
    class Map < Literal
      attr_reader :pairs
  
      def initialize(value)
        @pairs = value
      end
    end
  
    class Vector < Literal
      attr_reader :entries
  
      def initialize(value)
        @entries = value
      end
    end
  
    class Set < Literal
      attr_reader :elements
  
      def initialize(value)
        @elements = value
      end
    end
  
    class List < Literal
      attr_reader :elements
  
      def initialize(elements)
        @elements = elements
      end
    end
  
    class Symbol < Syntax
      include Interned
  
      attr_reader :namespace, :name
  
      def self.intern(ns, name)
        @values ||= {}
        @values[:"#{ns}/#{name}"] ||= new(ns, name)
      end
  
      def initialize(namespace, name)
        @namespace = namespace
        @name      = name
      end
    end
  
    class Variable < Syntax
      include Interned
  
      attr_reader :namespace, :name
  
      def self.intern(ns, name)
        @values ||= {}
        @values[:"#{ns}/#{name}"] ||= new(ns, name)
      end
  
      def initialize(namespace, name)
        if namespace
          @namespace = Util.encode_name(namespace)
          @name      = Util.encode_name(name)
        else
          @name = Util.encode_name(name)
        end
      end

      def to_s
        if namespace
          "#{namespace}/#{name}"
        else
          name.to_s
        end
      end
    end
  
    class Definition < Syntax
      attr_reader :name, :value
  
      def initialize(name, value)
        @name, @value = name, value
      end
    end
  
    class Conditional < Syntax
      attr_reader :predicates, :default
  
      def initialize(predicates, default)
        @predicates, @default = predicates, default
      end
    end
  
    class Quote < Syntax
      attr_reader :value
  
      def initialize(value)
        @value = value
      end
    end
  
    class MacroDefinition < Syntax
      attr_reader :name, :function

      def initialize(name, function)
        @name     = name
        @function = function
      end
    end
  
    class Block < Syntax
      attr_reader :expressions

      def initialize(expressions)
        @expressions = expressions
      end
    end

    class Lambda < Syntax
      attr_reader :id, :args, :body
  
      def initialize(args, body, capture=nil)
        @id      = Util.generate_id
        @args    = args
        @body    = body
        @capture = capture
      end
    end

    class ArgumentsVector < Syntax
      def initialize(names, capture=nil)
        @names   = names
        @capture = capture
      end
    end

    class LambdaBody < Syntax
      attr_reader :args, :block

      def initialize(args, block)
        @args    = args
        @block   = block
        @capture = capture
      end
    end
  
    class Loop < Syntax
      attr_reader :id, :bindings, :body
  
      def initialize(binds, body)
        @bindings = binds
        @body     = body
        @id       = Util.generate_id
      end
    end

    module TailCall
      def tailcall?
        @tailcall
      end

      def flag_as_tailcall!
        @tailcall = true
      end
    end

    module NotReturnable
    end

    class RecursionPoint
      attr_reader :args

      include TailCall
      include NotReturnable

      def initialize(args, tailcall=false)
        @args     = args
        @tailcall = tailcall
      end
    end

    class Bindings < Syntax
      attr_reader :names, :values

      def initialize(names, values)
        @names  = names
        @values = values
      end
    end
  
    class ExceptionHandler < Syntax
      attr_reader :try, :catch, :finally
  
      def initialize(try, cblock, finally)
        @try     = try
        @catch   = cblock
        @finally = finally
      end
    end

    class Exception < Syntax
      attr_reader :expression

      include NotReturnable

      def initialize(expression)
        @expression = expression
      end
    end
  
    class ClassInstantiation < Syntax
      attr_reader :name, :args
  
      def initialize(name, args)
        @name = name
        @args = args
      end
    end
  
    class MethodResolution < Syntax
      attr_reader :object, :method, :args
  
      def initialize(object, method, args)
        @object = object
        @method = method
        @args   = args
      end
    end
  
    class PropertyResolution < Syntax
      attr_reader :object, :property
  
      def initialize(object, property)
        @object   = object
        @property = property
      end
    end
  
    class Assignment < Syntax
      attr_reader :object, :value
  
      def initialize(object, value)
        @object = object
        @value  = value
      end
    end
  
    class Application < Syntax
      attr_reader :invocable, :args
  
      include TailCall

      def initialize(invocable, args, tailcall=false)
        @invocable = invocable
        @args      = args
        @tailcall  = tailcall
      end
    end
  
    class BinaryOperator < Application
      attr_reader :operator, :left, :right
  
      def initialize(operator, left, right)
        @operator, @left, @right = operator, left, right
      end
    end
  
    class UnaryOperator < Application
      attr_reader :operator, :expression
      
      def initialize(operator, expression)
        @operator, @expression = operator, expression
      end
    end
  
    class ArithmeticOperator < Application
      attr_reader :operator, :args
  
      def initialize(operator, args)
        @operator = operator
        @args     = args
      end
    end
  end
end
