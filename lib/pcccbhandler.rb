#    pcccbhandler.rb
#    ~~~~~~~~~
#    This module implements the PubControlClientCallbackHandler class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

# The PubControlClientCallbackHandler class is used internally for allowing
# an async publish call made from the PubControl class to execute a callback
# method only a single time. A PubControl instance can potentially contain
# many PubControlClient instances in which case this class tracks the number
# of successful publishes relative to the total number of PubControlClient
# instances. A failure to publish in any of the PubControlClient instances
# will result in a failed result passed to the callback method and the error
# from the first encountered failure.
class PubControlClientCallbackHandler

  # The initialize method accepts: a num_calls parameter which is an integer
  # representing the number of PubControlClient instances, and a callback
  # method to be executed after all publishing is complete.
  def initialize(num_calls, callback)
    @num_calls = num_calls
    @callback = callback
    @success = true
    @first_error_message = nil
  end

  # The handler method which is executed by PubControlClient when publishing
  # is complete. This method tracks the number of publishes performed and 
  # when all publishes are complete it will call the callback method
  # originally specified by the consumer. If publishing failures are
  # encountered only the first error is saved and reported to the callback
  # method.
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

  # This method is used as a workaround to retrieve the handler method symbol.
  # TODO: how to get handler symbol without this method?
  def handler_method_symbol
    return method(:handler)
  end
end
