module Nesting
  def nesting_for(object)
    (object.embedded? ? nesting_for(object._parent) : []) + [object]
  end
end
