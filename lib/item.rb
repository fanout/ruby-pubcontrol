#    item.rb
#    ~~~~~~~~~
#    This module implements the Item class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require_relative 'format.rb'

# The Item class is a container used to contain one or multiple format
# implementation instances. The type of format implementations may be
# of the same or different format types. An Item instance is serialized
# into a hash that is used for publishing to clients.
class Item

  # The initialize method can accept either a single format implementation
  # instance or an array of format implementation instances. Optionally
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
  # into a hash that is used for publishing to clients.
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
