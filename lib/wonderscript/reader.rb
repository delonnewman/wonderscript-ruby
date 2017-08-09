module WonderScript::Reader
  extend WonderScript::Analyzer

  def self.read_string(str)
    EDN::Reader.new(str)
  end

  def self.read_file(file)
    read_string(open(file))
  end
end
