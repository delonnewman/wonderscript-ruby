class Array
  def partition(n)
    i = 0
    new = []
    while i < size
      part = []
      j = 0
      while j < n
        part.push(self[i + j])
        j += 1
      end
      new.push(part)
      i += n
    end
    new
  end
end
