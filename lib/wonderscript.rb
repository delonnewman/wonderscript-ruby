require 'bundler/setup'
require 'edn'

module WonderScript
  VERSION = '0.0.1'.freeze
end

require_relative 'wonderscript/syntax'
require_relative 'wonderscript/analyzer'
require_relative 'wonderscript/reader'
require_relative 'wonderscript/compiler'
