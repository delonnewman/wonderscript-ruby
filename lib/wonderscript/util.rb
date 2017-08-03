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

    extend self
  end
end
