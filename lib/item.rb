#    item.rb
#    ~~~~~~~~~
#    This module implements the Item class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require_relative 'format.rb'

class Item
  def initialize(formats, id=nil, prev_id=nil)
    @id = id
    @prev_id = prev_id
    if formats.is_a? Format
      formats = [formats]
    end
    @formats = formats
  end

  def export
    out = Hash.new
    if !@id.nil?
      out['id'] = @id
    end
    if !@prev_id.nil?
      out['prev-id'] = @prev_id
    end
    @formats.each do |format|
      out[format.name] = format.export
    end
    return out
  end
end
