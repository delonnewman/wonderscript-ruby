require 'v8'

module WonderScript
  module Compiler::JavaScript
    extend Analyzer

    PRIMITIVE_FUNCTIONS = {
      'aset'   => lambda { |array, index, value| "#{array.to_js}[#{index.to_js}] = #{value.to_js}"  },
      'aget'   => lambda { |array, index| "#{array.to_js}[#{index.to_js}]"  },
      'array'  => lambda { |*args| "[#{args.map(&:to_js).join(', ')}]" },
      'object' => lambda { |*args| "{#{args.partition(2).map { |x| "#{x[0].to_js}:#{x[1].to_js}" }.join(', ')}}" },
      'str'    => lambda { |*args| "[#{args.map(&:to_js).join(', ')}].join('')" },
      'p'      => lambda { |*args| "console.log(#{args.map(&:to_js).join(', ')})" },
    }

    IMPORTS = {
      'Array' => 'Array'
    }

    def self.compile(form)
      analyze(form).to_js
    end
  end

  module Syntax
    class Syntax
      def primitive?
        false
      end
    end

    class Nil
      def to_js
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

      def primitive?
        true
      end
    end

    class Number
      def to_js
        value.to_s
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
    end

    class String
      def to_js
        "'#{value}'"
      end

      def primitive?
        true
      end
    end

    class Map
      def to_js
        "ws.core.hashMap(#{pairs.map { |x| "#{x[0].to_js}, #{x[1].to_js}" }.join(',')})"
      end
    end

    class Vector
      def to_js
        "ws.core.vector(#{entries.map(&:to_js).join(',')})"
      end
    end

    class Set
      def to_js
        "ws.core.set([#{elements.map(&:to_js).join(',')}])"
      end
    end

    class List
      def to_js
        "ws.core.list(#{elements.map(&:to_js).join(',')})"
      end
    end
    
    class Variable
      def to_js
        if namespace.nil?
          if import = Compiler::JavaScript::IMPORTS[name]
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
          "var #{nm}=#{value.to_js}"
        else
          nspath = ns.split('.')
          if nspath.size == 1
            "#{ns}.#{nm}=#{value.to_js}"
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
            "var #{str}\n#{ns}.#{nm}=#{value.to_js}"
          end
        end
      end
    end

    class Conditional
      def to_js
        first = predicates.first
        rest  = predicates.rest.map { |pred| "else if (#{pred[0].to_js}) { return #{pred[1].to_js}; }" }.join("\n")
        default_ =
          if default.is_a? RecursionPoint or default.is_a? Exception
            "#{default.to_js};"
          else
            "return #{default.to_js};"
          end
        "(function() {
           if (#{first[0].to_js}) {
              return #{first[1].to_js};
           }
           #{rest}
           else {
              #{default_};
           }
        }())"
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
    end

    class Quote
      def to_js
        value.to_js
      end
    end

    class MacroDefinition
      def js
        @js ||= V8::Context.new
      end

      def to_js
        raise 'name should be a symbol' unless name.is_a? Variable
        code = function.to_js
        WonderScript::MACROS[name.to_s] = js.eval(code)
        nil
      end
    end

    class Block
      def to_js
        last =
          if expressions.last.is_a? NotReturnable
            "#{expressions.last.to_js};"
          else
            "return #{expressions.last.to_js};"
          end
        rest = expressions.take(expressions.size - 1).map(&:to_js).join(';')
        if rest.empty?
          last
        else
          "#{rest};\n#{last}"
        end
      end
    end

    class Lambda
      def to_js
        xs = args.map(&:to_js)
        capture = xs.drop_while { |x| x[0] != '&' }.reject { |x| x == '&' }.map { |x| x.sub(/^&/, '') }
        names   = xs.take_while { |x| x[0] != '&' }
        raise 'Cannot list arguments after capture variable' unless capture.size <= 1
        if body.expressions.empty?
          "(function(#{names.join(' ')}){})"
        else
          if capture.empty?
            argcheck = "if (arguments.length !== #{names.size}) throw new Error('Wrong number of arguments, expected: #{names.size}, got: ' + arguments.length);"
            "(function(#{names.join(', ')}){ #{argcheck} #{body.to_js} })"
          else
            if names.size > 0
              argcheck = "if (arguments.length < #{names.size}) throw new Error('Wrong number of arguments, expected at least: #{names.size}, got: ' + arguments.length);"
              "(function(#{names.join(', ')}){ #{argcheck} var #{capture[0]} = Array.prototype.slice.call(arguments, #{names.size}); #{body.to_js} })"
            else
              "(function(#{names.join(', ')}){ var #{capture[0]} = Array.prototype.slice.call(arguments, #{names.size}); #{body.to_js} })"
            end
          end
        end
      end
    end

    class Loop
      def to_js
        names = bindings.names
        values = bindings.values
        rebinds = names.map.with_index { |x, i| "#{x.to_js} = e.args[#{i}]" }.join(';')
        "(function(#{names.map(&:to_js).join(', ')}){
          while (true) {
            try {
              #{body.to_js}
              break;
            }
            catch (e) {
              if (e instanceof ws.core.RecursionPoint) {
                #{rebinds};
                continue;
              }
              else {
                throw e;
              }
            }
          }
        }(#{values.map(&:to_js).join(', ')}))"
      end
    end

    class TypeDefinition
      def to_js
        binds = attributes.map { |attr| "this.#{attr.to_js} = #{attr.to_js}" }.join(';')
        protos = protocols.map { |proto| "#{proto.to_js}(ctr.prototype)" }.join(";\n")
        meths  = methods.map { |meth| "ctr.prototype.#{meth.to_js}" }.join(";\n")
        "(function(){
        var ctr = function(#{attributes.map(&:to_js).join(', ')}) {
            #{binds};
        }
        ctr.prototype = {};
        #{protos};
        #{meths};
        return ctr;
        }())"
      end
    end

    class TypeMethod
      def to_js
        xs = args.map(&:to_js)
        capture = xs.drop_while { |x| x[0] != '&' }.reject { |x| x == '&' }.map { |x| x.sub(/^&/, '') }
        names   = xs.take_while { |x| x[0] != '&' }
        argc    = names.size - 1
        this    = names.first
        args_   = names.drop(1)
        #binds   = args_.map { |x| "var #{x} = this.#{x}" }.join(';')
        raise 'Cannot list arguments after capture variable' unless capture.size <= 1
        if body.expressions.empty?
          "#{name.to_js} = (function(#{names.drop(1).join(', ')}){})"
        else
          if capture.empty?
            if names.size > 0
              argcheck = "if (arguments.length !== #{argc}) throw new Error('Wrong number of arguments, expected: #{argc}, got: ' + arguments.length);"
              "#{name.to_js} = (function(#{args_.join(', ')}){ var #{this} = this; #{argcheck} #{body.to_js} })"
            else
              "#{name.to_js} = (function(){ #{body.to_js} })"
            end
          else
            if names.size > 0
              argcheck = "if (arguments.length < #{argc}) throw new Error('Wrong number of arguments, expected at least: #{argc}, got: ' + arguments.length);"
              "#{name.to_js} = (function(#{args_.join(', ')}){ #{argcheck} var #{this} = this; var #{capture[0]} = Array.prototype.slice.call(arguments, #{argc}); #{body.to_js} })"
            else
              "#{name.to_js} = (function(){ var #{capture[0]} = Array.prototype.slice.call(arguments, #{argc}); #{body.to_js} })"
            end
          end
        end
      end
    end

    class RecursionPoint
      def to_js
        "throw new ws.core.RecursionPoint([#{args.map(&:to_js).join(', ')}])";
      end
    end

    class ExceptionHandler

    end

    class Exception
      def to_js
        "throw #{expression.to_js};"
      end
    end

    class ClassInstantiation
      def to_js
        "(new #{name.to_js}(#{args.map(&:to_js).join(',')}))"
      end
    end

    class MethodResolution
      def to_js
        "#{object.to_js}.#{method.name}(#{args.map(&:to_js).join(', ')})"
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
        subject = invocable.to_js
        if func = Compiler::JavaScript::PRIMITIVE_FUNCTIONS[subject]
          func.call(*args)
        else
          "#{subject}(#{args.map(&:to_js).join(',')})"
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
