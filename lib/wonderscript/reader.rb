module WonderScript::Reader
  extend WonderScript::Analyzer

  def self.read(str)
    EDN::Reader.new(str)
  end

  def self.read_file(file)
    read(open(file))
  end
end
