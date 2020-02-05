module WonderScript
  module Compiler
    class Ruby
      extend Analyzer

      PRIMITIVE_FUNCTIONS = {
        'aset'   => lambda { |array, index, value| "#{array.to_ruby}[#{index.to_ruby}] = #{value.to_ruby}"  },
        'aget'   => lambda { |array, index| "#{array.to_ruby}[#{index.to_ruby}]"  },
        'array'  => lambda { |*args| "[#{args.map(&:to_ruby).join(', ')}]" },
        'str'    => lambda { |*args| "#{args.map(&:to_ruby).join('.to_s +')}" },
        'p'      => lambda { |*args| "p(#{args.map(&:to_ruby).join(', ')})" },
      }
      
      IMPORTS = {
        'Array' => 'Array'
      }

      def self.compile(form)
        analyze(form).to_ruby
      end
    end
  end

  module Syntax
    class Syntax
      def primitive?
        false
      end
    end

    class Nil
      def to_ruby
        'nil'
      end

      def primitive?
        true
      end
    end

    class Boolean
      def to_ruby
        value ? 'true' : 'false'
      end

      def primitive?
        true
      end
    end

    class Number
      def to_ruby
        value.to_s
      end

      def primitive?
        true
      end
    end

    class Keyword
      def to_ruby
        if namespace.nil?
          ":#{name}"
        else
          ":'#{namespace}/#{name}'"
        end
      end
    end

    class String
      def to_ruby
        "'#{value}'"
      end

      def primitive?
        true
      end
    end

    class Map
      def to_ruby
        "WS::Map[#{pairs.map { |x| "#{x[0].to_ruby} => #{x[1].to_ruby}" }.join(',')}]"
      end
    end

    class Vector
      def to_ruby
        "WS::Vector[#{entries.map(&:to_ruby).join(',')}]"
      end
    end

    class Set
      def to_ruby
        "WS::Set[#{elements.map(&:to_ruby).join(',')}]"
      end
    end

    class List
      def to_ruby
        "WS::List[#{elements.map(&:to_ruby).join(',')}]"
      end
    end
    
    class Variable
      def to_ruby
        if namespace.nil?
          if import = Compiler::Ruby::IMPORTS[name]
            import
          else
            "#{name}"
          end
        else
          "#{namespace.capitalize}::#{name}"
        end
      end
    end

    class Definition
      def to_ruby
        ns = name.namespace
        nm = name.name
        if ns.nil?
          "#{nm}=#{value.to_ruby}"
        else
          nspath = ns.split('.').map(&:capitalize)
          if nspath.size == 1
            "module #{nspath.first}\n\tdef self.#{nm}\n\t\t#{value.to_ruby}\n\tend\nend"
          else
            p nspath
            "test"
          end
        end
      end
    end

    class Conditional
      def to_ruby
        first = predicates.first
        rest  = predicates.rest.map { |pred| "elsif #{pred[0].to_ruby} then #{pred[1].to_ruby}" }.join("\n")
        "if #{first[0].to_ruby}
        #{first[1].to_ruby}
        #{rest}
        else
          #{default.to_ruby}
        end"
      end
    end

    class Symbol
      def to_ruby
        if namespace.nil?
          "WS::Symbol.new(nil, '#{name}')"
        else
          "WS::Symbol.new('#{namespace}', '#{name}')"
        end
      end
    end

    class Quote
      def to_ruby
        value.to_ruby
      end
    end

    class MacroDefinition
      def to_ruby
        raise 'name should be a symbol' unless name.is_a? Variable
        code = function.to_ruby
        WonderScript::MACROS[name.to_s] = eval(code)
        nil
      end
    end

    class Block
      def to_ruby
        expressions.take(expressions.size - 1).map(&:to_ruby).join("\n")
      end
    end

    class Lambda
      def to_ruby
        xs = args.map(&:to_ruby)
        capture = xs.drop_while { |x| x[0] != '&' }.reject { |x| x == '&' }.map { |x| x.sub(/^&/, '') }
        names   = xs.take_while { |x| x[0] != '&' }
        raise 'Cannot list arguments after capture variable' unless capture.size <= 1
        names.push("*#{capture[0]}")
        "lambda { |#{names.join(', ')}| #{body.to_ruby} }"
      end
    end

    class Loop
      def to_ruby
        raise 'undefined'
      end
    end

    class TypeDefinition
      def to_ruby
        raise 'undefined'
      end
    end

    class TypeMethod
      def to_ruby
        raise 'undefined'
      end
    end

    class RecursionPoint
      def to_ruby
        raise 'undefined'
      end
    end

    class ExceptionHandler
      def to_ruby
        raise 'undefined'
      end
    end

    class Exception
      def to_ruby
        "raise #{expression.to_ruby}"
      end
    end

    class ClassInstantiation
      def to_ruby
        "#{name.to_ruby}.new(#{args.map(&:to_ruby).join(',')})"
      end
    end

    class MethodResolution
      def to_ruby
        "#{object.to_ruby}.#{method.name}(#{args.map(&:to_ruby).join(', ')})"
      end
    end

    class PropertyResolution
      def to_ruby
        "#{object.to_ruby}.#{property.name}"
      end
    end

    class Assignment
      def to_ruby
        "#{object.to_ruby}=#{value.to_ruby}"
      end
    end

    class Application
      def to_ruby
        subject = invocable.to_ruby
        if func = Compiler::Ruby::PRIMITIVE_FUNCTIONS[subject]
          func.call(*args)
        else
          "#{subject}[#{args.map(&:to_ruby).join(',')}]"
        end
      end
    end

    class BinaryOperator
      def to_ruby
        "(#{left.to_ruby}#{operator.to_ruby}#{right.to_ruby})"
      end
    end

    class UnaryOperator
      def to_ruby
        "#{operator.to_ruby}#{expression.to_ruby}"
      end
    end

    class ArithmeticOperator
      def to_ruby
        argc = args.size
        op   = operator.to_ruby
        case op
        when '+'
          case argc
          when 0 then 0
          when 1 then "#{op}#{args[0].to_ruby}"
          else
            "(#{args.map(&:to_ruby).join(op)})"
          end
        when '-'
          case argc
          when 0 then 0
          when 1 then "#{op}#{args[0].to_ruby}"
          else
            "(#{args.map(&:to_ruby).join(op)})"
          end
        when '*'
          case argc
          when 0 then 1
          when 1 then args[0].to_ruby
          else
            "(#{args.map(&:to_ruby).join(op)})"
          end
        when '/'
          case argc
          when 0 then 1
          when 1 then args[0].to_ruby
          else
            "(#{args.map(&:to_ruby).join(op)})"
          end
        else
          raise "invalid arithmetic operator: #{op}"
        end
      end
    end
  end
end
