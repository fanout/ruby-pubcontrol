#    format.rb
#    ~~~~~~~~~
#    This module implements the Format class.
#    :copyright: (c) 2014 by Fanout.io.
#    :license: MIT, see LICENSE for more details.

class Format
  def name
    raise NotImplementedError
  end

  def export
    raise NotImplementedError
  end
end
