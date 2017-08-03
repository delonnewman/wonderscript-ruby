module WonderScript
  module Compiler::JavaScript
    extend Analyzer

    def self.compile(form)
      analyze(form).to_js
    end
  end

  module Syntax
    CHAR_MAP = {
      '!' => '__BANG__',
      '$' => '__DOLLAR__',
      '#' => '__POUND__',
      '-' => '__DASH__',
      '@' => '__AT__',
      '%' => '__PER__',
      '^' => '__HAT__',
      '*' => '__STAR__',
      '>' => '__GT__',
      '<' => '__LT__',
      '?' => '__QEST__'
    }

    def self.encode_name(str)
      return nil unless str
      buff = StringIO.new
      for i in 0..str.length
        if ch = CHAR_MAP[str[i]]
          buff.print ch 
        else
          buff.print str[i]
        end
      end
      buff.string
    end

    class Nil
      def to_js
        'null'
      end
    end

    class Boolean
      def to_js
        value ? 'true' : 'false'
      end
    end

    class Number
      def to_js
        value.to_s
      end
    end

    class Keyword
      def to_js
        if namespace.nil?
          "mori.keyword('#{name}')"
        else
          "mori.keyword('#{namespace}', '#{name}')"
        end
      end
    end

    class String
      def to_js
        "'#{value}'"
      end
    end

    class Map
      def to_js
        "mori.hashMap(#{pairs.map { |x| "#{x[0].to_js}, #{x[1].to_js}" }.join(',')})"
      end
    end

    class Vector
      def to_js
        "mori.vector(#{entries.map(&:to_js).join(',')})"
      end
    end

    class Set
      def to_js
        "mori.set([#{elements.map(&:to_js).join(',')}])"
      end
    end

    class List
      def to_js
        "mori.list(#{elements.map(&:to_js).join(',')})"
      end
    end
    
    class Variable
      def to_js
        if namespace.nil?
          name
        else
          "#{namespace}.#{name}"
        end
      end
    end

    class Definition
      def to_js
        ns = ::Syntax.encode_name(name.namespace)
        nm = ::Syntax.encode_name(name.name)
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
          "mori.symbol('#{name}')"
        else
          "mori.symbol('#{namespace}', '#{name}')"
        end
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
          "(function(#{args.map(&:to_js).join(' ')}){ #{rest}#{last} })"
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
        "#{object.to_js}.#{method.to_js}(#{args.map(&:to_js).join('')})"
      end
    end

    class PropertyResolution
      def to_js
        "#{object.to_js}['#{property.to_js}']"
      end
    end

    class Assignment
      def to_js
        "#{object.to_js}=#{value.to_js}"
      end
    end

    class Application
      def to_js
        if invocable.is_a? Variable
          "#{::Syntax.encode_name(invocable.to_js)}(#{args.map(&:to_js).join(',')})"
        else
          "#{invocable.to_js}(#{args.map(&:to_js).join(',')})"
        end
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
