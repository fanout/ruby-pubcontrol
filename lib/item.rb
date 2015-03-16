#    item.rb
#    ~~~~~~~~~
#    This module implements the Item class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require_relative 'format.rb'

# The Item class is a container used to contain one or more format
# implementation instances where each implementation instance is of a
# different type of format. An Item instance may not contain multiple
# implementations of the same type of format. An Item instance is then
# serialized into a hash that is used for publishing to clients.
class Item

  # The initialize method can accept either a single Format implementation
  # instance or an array of Format implementation instances. Optionally
  # specify an ID and/or previous ID to be sent as part of the message
  # published to the client.
  def initialize(formats, id=nil, prev_id=nil)
    @id = id
    @prev_id = prev_id
    if formats.is_a? Format
      formats = [formats]
    end
    @formats = formats
  end

  # The export method serializes all of the formats, ID, and previous ID
  # into a hash that is used for publishing to clients. If more than one
  # instance of the same type of Format implementation was specified then
  # an error will be raised.
  def export
    format_types = []
    @formats.each do |format|
      if !format_types.index(format.class.name).nil?
        raise 'more than one instance of ' + format.class.name + ' specified'
      end
      format_types.push(format.class.name)
    end
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
