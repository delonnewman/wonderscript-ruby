module WonderScript
  module Util
    def parse_symbol(x)
      parts = x.to_s.split('/')
      if parts.size === 1
        [nil, parts[0]]
      else
        parts
      end
    end

    def generate_id
      MurmurHash3::V32.fmix(SecureRandom.hex(4).hex)
    end

    RESERVED_CHARS = {
      '!' => '__BANG__',
      #'$' => '__DOLLAR__',
      '#' => '__POUND__',
      '-' => '__DASH__',
      '@' => '__AT__',
      '%' => '__PER__',
      '^' => '__HAT__',
      '*' => '__STAR__',
      '>' => '__GT__',
      '<' => '__LT__',
      '?' => '__QEST__',
      '~' => '__CURL__',
      '|' => '__PIPE__',
      '+' => '__PLUS__',
      '/' => '__BSLASH__',
      '\\' => '__FSLASH__'
    }

    RESERVED_WORDS = {
      'default'   => '__DEFAULT__',
      'class'     => '__CLASS__',
      'function'  => '__FUNC__',
      'function*' => '__FUNC_STAR__',
      'return'    => '__RETURN__',
      'throw'     => '__THROW__',
      'catch'     => '__CATCH__',
      'finaly'    => '__FINALLY__',
      'if'        => '__IF__',
      'else'      => '__ELSE__',
      'switch'    => '__SWITCH__',
      'case'      => '__CASE__',
      'break'     => '__BREAK__',
      'continue'  => '__CONTINUE__',
      'const'     => '__CONST__',
      'var'       => '__VAR__',
      'let'       => '__LET__',
      'do'        => '__DO__',
      'for'       => '__FOR__',
      'while'     => '__WHILE__',
      'each'      => '__EACH__',
      'in'        => '__IN__',
      'of'        => '__OF__',
      'debugger'  => '__DEBUGGER__',
      'import'    => '__IMPORT__',
      'with'      => '__WITH__',
      'async'     => '__ASYNC__',
      'this'      => '__THIS__',
      'arguments' => '__ARGS__'
    }

    def reserved_word?(str)
      !!RESERVED_WORDS[str];
    end
  
    BINARY_OPERATORS = {
      :<                          =>  :<,
      :<=                         => :<=,
      :>                          => :>,
      :>=                         => :>=,
      :mod                        => :%,
      :'bit-and'                  => :&,
      :'bit-or'                   => :|,
      :'bit-xor'                  => :^,
      :'bit-shift-right'          => :>>,
      :'unsigned-bit-shift-right' => :'>>>',
      :'bit-shift-left'           => :<<,
      :'identical?'               => :'===', # PHP same, Ruby Object#equal?
      :'eqiv?'                    => :'==',  # PHP same, Ruby ===, Ruby also provides has equality with Object#eql?, and ==
      :and                        => :'&&',
      :or                         => :'||',
      :instance?                  => :'instanceof',
    }
  
    def binary_operator? tag
      !!BINARY_OPERATORS[tag]
    end
  
    UNARY_OPERATORS = {
      :not       => :!,
      :'bit-not' => :~
    }
  
    def unary_operator? tag
      !!UNARY_OPERATORS[tag]
    end
  
    ARITHMETIC_OPERATORS = {
      :+   => :+,
      :-   => :-,
      :*   => :*,
      :div => :/   # div exposes floating point division when needed '/' will return a Rational type
    }

    JSOPERATORS =
      BINARY_OPERATORS
        .merge(UNARY_OPERATORS)
        .merge(ARITHMETIC_OPERATORS)
        .reduce({}) { |h, kv| h.merge(kv[1] => kv[0]) }
  
    def arithmetic_operator? tag
      !!ARITHMETIC_OPERATORS[tag]
    end

    def operator?(str)
      tag = str.to_sym
      binary_operator?(tag) or unary_operator?(tag) or arithmetic_operator?(tag)
    end

    def js_operator?(str)
      !!JSOPERATORS[str.to_sym]
    end

    def encode_name(str)
      if str.nil?
        nil
      elsif js_operator?(str)
        str
      elsif reserved_word?(str)
        RESERVED_WORDS[str];
      else
        buff = StringIO.new
        for i in 0..str.length
          if ch = RESERVED_CHARS[str[i]]
            buff.print ch 
          else
            buff.print str[i]
          end
        end
        buff.string
      end
    end

    extend self
  end
end
