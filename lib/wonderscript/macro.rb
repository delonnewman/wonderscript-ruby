module WonderScript
  MACROS = {}

  def macroexpand(exp)
    if exp.is_a? EDN::Type::List and macro = MACROS[exp.first.to_s]
      macroexpand(macro.call(*exp.drop(1)))
    else
      exp
    end
  end
end
