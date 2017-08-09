require 'set'

module WS
  class Vector
    def self.[](*args)
      args
    end
  end

  class Map
    def self.[](hash)
      hash
    end
  end

  class Set
    def self.[](*args)
      ::Set.new(args)
    end
  end

  class Symbol
    attr_reader :namespace, :name

    def initialize(ns, name)
      @namespace = ns
      @name      = name
    end
  end

  class List < Array
  end

  def self.str(*args)

  end

  def self.partition(col, n)

  end
end
