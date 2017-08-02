module WonderScript::Reader
  extend WonderScript::Analyzer

  def self.read_string(str)
    analyze(EDN.read(str))
  end
end
