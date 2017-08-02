module WonderScript::Syntax
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

    def self.intern(value)
      @values ||= {}
      @values[value] ||= new(value)
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

  class Variable < Syntax
    attr_reader :namespace, :name

    def initialize(namespace, name)
      @namespace = namespace
      @name      = name
    end
  end

  class Definition < Syntax
    attr_reader :name, :value

    def initialize(name, value)
      @name, @value = name, value
    end
  end

  class Conditional < Syntax
    attr_reader :predicate, :consequent, :alternate

    def initialize(predicate, conseqent, alternate)
      @predicate, @consequent, @alternate = predicate, conseqent, alternate
    end
  end

  class Quote < Syntax
    attr_reader :value

    def initialize(value)
      @value = value
    end
  end

  class MacroDefinition < Syntax
    attr_reader :name, :args, :body

    def initialize(name, args, body)
      @name = name
      @args = args
      @body = body
    end
  end

  class Lambda < Syntax
    attr_reader :args, :body

    def initialize(args, body)
      @args = args
      @body = body
    end
  end

  class Loop < Syntax
    attr_reader :bindings, :body

    def initialize(binds, body)
      @bindings = binds
      @body     = body
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

  class ClassInstatiation < Syntax
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

    def initialize(invocable, args)
      @invocable = invocable
      @args      = args
    end
  end
end
