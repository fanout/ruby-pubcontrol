#    format.rb
#    ~~~~~~~~~
#    This module implements the PubControlCallbackHandler class.
#    :copyright: (c) 2014 by Fanout.io.
#    :license: MIT, see LICENSE for more details.

class PubControlCallbackHandler
  def initialize(num_calls, callback)
    @num_calls = num_calls
    @callback = callback
    @success = true
    @first_error_message = nil
  end

  def handler(success, message)
    if !success and @success
      @success = false
      @first_error_message = message
    end
    @num_calls -= 1
    if @num_calls <= 0
      @callback.call(@success, @first_error_message)
    end
  end

  # TODO: how to get handler symbol without this method?
  def handler_method_symbol
    return method(:handler)
  end
end
