module WonderScript
  module Compiler::JavaScript
    extend Analyzer

    def self.compile(form)
      analyze(form).to_js
    end
  end

  module Syntax
    class Syntax
      def goog_type
        '*'
      end

      def primitive?
        false
      end
    end

    class Nil
      def to_js
        'null'
      end

      def goog_type
        'null'
      end

      def primitive?
        true
      end
    end

    class Boolean
      def to_js
        value ? 'true' : 'false'
      end

      def goog_type
        'boolean'
      end

      def primitive?
        true
      end
    end

    class Number
      def to_js
        value.to_s
      end

      def goog_type
        'number'
      end

      def primitive?
        true
      end
    end

    class Keyword
      def to_js
        if namespace.nil?
          "ws.core.keyword('#{name}')"
        else
          "ws.core.keyword('#{namespace}', '#{name}')"
        end
      end
      
      def goog_type
        'Object'
      end
    end

    class String
      def to_js
        "'#{value}'"
      end

      def goog_type
        'string'
      end

      def primitive?
        true
      end
    end

    class Map
      def to_js
        "ws.core.hashMap(#{pairs.map { |x| "#{x[0].to_js}, #{x[1].to_js}" }.join(',')})"
      end

      def goog_type
        'Object'
      end
    end

    class Vector
      def to_js
        "ws.core.vector(#{entries.map(&:to_js).join(',')})"
      end

      def goog_type
        'Object'
      end
    end

    class Set
      def to_js
        "ws.core.set([#{elements.map(&:to_js).join(',')}])"
      end

      def goog_type
        'Object'
      end
    end

    class List
      def to_js
        "ws.core.list(#{elements.map(&:to_js).join(',')})"
      end

      def goog_type
        'Object'
      end
    end
    
    IMPORTS = {
      'goog.provide' => 'goog.provide',
      'Array'        => 'Array'
    }

    class Variable
      def to_js
        if namespace.nil?
          if import = IMPORTS[name]
            import
          else
            "#{name}"
          end
        else
          "#{namespace}.#{name}"
        end
      end
    end

    class Definition
      def to_js
        ns = name.namespace
        nm = name.name
        if ns.nil?
          "var #{nm}=#{value.to_js};"
        else
          nspath = ns.split('.')
          if nspath.size == 1
            "#{ns}['#{nm}']=#{value.to_js}"
          else
            str = nspath.reduce([]) do |memo, x|
              if memo.last.nil?
                memo << [x]
              else
                memo << (memo.last.map { |y| y } << x)
              end
            end
            .map do |path|
              p = path.join('.')
              "#{p}=#{p}||{};"
            end
            .join("\n")
            "var #{str}\n#{ns}['#{nm}']=#{value.to_js}"
          end
        end
      end
    end

    class Conditional
      def to_js
        "(#{predicate.to_js}?#{consequent.to_js}:#{alternate.to_js})"
      end
    end

    class Symbol
      def to_js
        if namespace.nil?
          "ws.core.symbol('#{name}')"
        else
          "ws.core.symbol('#{namespace}', '#{name}')"
        end
      end

      def goog_type
        'Object'
      end
    end

    class Quote
      def to_js
        value.to_js
      end
    end

    class MacroDefinition

    end

    class Lambda
      def to_js
        if body.empty?
          "(function(#{args.map(&:to_js).join(' ')}){})"
        else
          last = "return #{body.last.to_js};"
          rest = body.take(body.size - 1).map(&:to_js).join(';')
          "(function(#{args.map(&:to_js).join(', ')}){ #{rest}; #{last} })"
        end
      end

      # TODO: type annotations could help here
      def goog_type
        if args.empty?
          "function(...)"
        else
          "function(#{args.map(&:goog_type).join(', ')})"
        end
      end
    end

    class Loop
      def to_js
        "
        // bind vars
        try {
          // execute body
        }
        catch (e) {
          if (e instanceof ws.core.RecursionPoint) {
            // rebind vars and re-execute
          }
          else {
            throw e;
          }
        }
        "
      end
    end

    class ExceptionHandler

    end

    class ClassInstantiation
      def to_js
        "(new #{name.to_js}(#{args.map(&:to_js).join(',')}))"
      end
    end

    class MethodResolution
      def to_js
        "#{object.to_js}.#{method.name}(#{args.map(&:to_js).join('')})"
      end
    end

    class PropertyResolution
      def to_js
        "#{object.to_js}.#{property.name}"
      end
    end

    class Assignment
      def to_js
        "#{object.to_js}=#{value.to_js}"
      end
    end

    class Application
      def to_js
        "#{invocable.to_js}(#{args.map(&:to_js).join(',')})"
      end
    end

    class BinaryOperator
      def to_js
        "(#{left.to_js}#{operator.to_js}#{right.to_js})"
      end
    end

    class UnaryOperator
      def to_js
        "#{operator.to_js}#{expression.to_js}"
      end
    end

    class ArithmeticOperator
      def to_js
        argc = args.size
        op   = operator.to_js
        case op
        when '+'
          case argc
          when 0 then 0
          when 1 then "#{op}#{args[0].to_js}"
          else
            "(#{args.map(&:to_js).join(op)})"
          end
        when '-'
          case argc
          when 0 then 0
          when 1 then "#{op}#{args[0].to_js}"
          else
            "(#{args.map(&:to_js).join(op)})"
          end
        when '*'
          case argc
          when 0 then 1
          when 1 then args[0].to_js
          else
            "(#{args.map(&:to_js).join(op)})"
          end
        when '/'
          case argc
          when 0 then 1
          when 1 then args[0].to_js
          else
            "(#{args.map(&:to_js).join(op)})"
          end
        else
          raise "invalid arithmetic operator: #{op}"
        end
      end
    end
  end
end
