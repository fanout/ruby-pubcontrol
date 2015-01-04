#    format.rb
#    ~~~~~~~~~
#    This module implements the Format class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

class Format
  def name
    raise NotImplementedError
  end

  def export
    raise NotImplementedError
  end
end
