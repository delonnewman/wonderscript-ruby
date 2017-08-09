require 'bundler/setup'
require 'edn'
require 'stringio'
require 'securerandom'
require 'murmurhash3'

module WonderScript
  VERSION = '0.0.1'.freeze
end

require_relative 'wonderscript/util'
require_relative 'wonderscript/syntax'
require_relative 'wonderscript/analyzer'
require_relative 'wonderscript/reader'
require_relative 'wonderscript/compiler'
require_relative 'wonderscript/macro'
