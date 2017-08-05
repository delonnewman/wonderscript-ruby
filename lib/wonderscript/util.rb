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
      '?' => '__QEST__',
      '~' => '__CURL__',
      '|' => '__PIPE__'
    }

    RESERVED_WORDS = {
      'default' => '__DEFAULT__',
      'return'  => '__RETURN__'
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
      :'='                        => :'===',
      :'not='                     => :'!=='
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
      :+ => :+,
      :- => :-,
      :* => :*,
      :/ => :/
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
          if ch = CHAR_MAP[str[i]]
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
