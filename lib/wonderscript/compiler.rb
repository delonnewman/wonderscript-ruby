module WonderScript
  module Compiler
    class << self
      def compile(form, target: :javascript)
        case target
        when :javascript
          WonderScript::Compiler::JavaScript.compile(form)
        else
          raise "don't know how to compile to target #{t.inspect}"
        end
      end

      def compile_string(str, target: :javascript)
        io = StringIO.new
        r  = Reader.read_string(str)
        r.each do |form|
          io.puts "#{compile(form, target: target)};"
        end
      end

      def compile_file(file, target: :javascript)
        io = StringIO.new
        r  = Reader.read_file(file)
        r.each do |form|
          io.puts "#{compile(form, target: target)};"
        end
        io.string
      end
    end
  end
end
