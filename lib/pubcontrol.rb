#    pubcontrol.rb
#    ~~~~~~~~~
#    This module implements the PubControl class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require_relative 'format.rb'
require_relative 'item.rb'
require_relative 'pubcontrolclient.rb'
require_relative 'pcccbhandler.rb'

# Register the close_pubcontrols method with at_exit to ensure that it is
# called on exit.
at_exit do
  PubControl.close_pubcontrols
end

# The PubControl class allows a consumer to manage a set of publishing
# endpoints and to publish to all of those endpoints via a single publish
# or publish_async method call. A PubControl instance can be configured
# either using a hash or array of hashes containing configuration information
# or by manually adding PubControlClient instances.
class PubControl
  # The global list of PubControl instances used to ensure that each instance
  # is properly closed on exit.
  @@pubcontrols = Array.new
  @@lock = Mutex.new

  # Initialize with or without a configuration. A configuration can be applied
  # after initialization via the apply_config method.
  def initialize(config=nil)
    @clients = Array.new
    @closed = false
    if !config.nil?
      apply_config(config)
    end
    @@lock.synchronize do
      @@pubcontrols.push(self)
    end
  end

  # Remove all of the configured PubControlClient instances.
  def remove_all_clients
    @clients = Array.new
  end

  # Add the specified PubControlClient instance.
  def add_client(client)
    @clients.push(client)
  end

  # Apply the specified configuration to this PubControl instance. The
  # configuration object can either be a hash or an array of hashes where
  # each hash corresponds to a single PubControlClient instance. Each hash
  # will be parsed and a PubControlClient will be created either using just
  # a URI or a URI and JWT authentication information.
  def apply_config(config)
    if !config.is_a?(Array)
      config = [config]
    end
    config.each do |entry|
      pub = PubControlClient.new(entry['uri'])
      if entry.key?('iss')
        pub.set_auth_jwt({'iss' => entry['iss']}, entry['key'])
      end
      @clients.push(pub)
    end
  end

  # The close method is a blocking call that closes all ZMQ sockets and
  # ensures that all PubControlClient async publishing is completed prior
  # to returning and allowing the consumer to proceed. Note that the
  # PubControl instance cannot be used after calling this method.
  def close
    close_clients
    unregister_pubcontrol
  end

  # Internal close method, used during shutdown while class lock is held.
  def close_locked
    close_clients
    unregister_pubcontrol_locked
  end

  # This method is a blocking method that ensures that all asynchronous
  # publishing is complete for all of the configured client instances prior
  # to returning and allowing the consumer to proceed.
  # NOTE: This only applies to PubControlClient and not ZmqPubControlClient
  # since all ZMQ socket operations are non-blocking.
  def wait_all_sent
    verify_not_closed
    @clients.each do |pub|
      pub.wait_all_sent
    end
  end

  # DEPRECATED: The finish method is now deprecated in favor of the more
  # descriptive wait_all_sent method.
  def finish
    verify_not_closed
    wait_all_sent
  end

  # The synchronous publish method for publishing the specified item to the
  # specified channels for all of the configured PubControlClient instances.
  def publish(channels, item)
    @clients.each do |pub|
      pub.publish(channels, item)
    end
  end

  # The asynchronous publish method for publishing the specified item to the
  # specified channels on the configured endpoint. The callback method is
  # optional and will be passed the publishing results after publishing is
  # complete. Note that a failure to publish in any of the configured
  # PubControlClient instances will result in a failure result being passed
  # to the callback method along with the first encountered error message.
  def publish_async(channels, item, callback=nil)
    cb = nil
    if !callback.nil?
      cb = PubControlClientCallbackHandler.new(@clients.length, callback).
          handler_method_symbol
    end
    @clients.each do |pub|
      pub.publish_async(channels, item, cb)
    end
  end

  # An internal method used for closing all existing PubControl instances.
  def self.close_pubcontrols
    @@lock.synchronize do
      pubcontrols = Array.new(@@pubcontrols)
      pubcontrols.each do |pub|
        pub.close_locked
      end
    end
  end

  private

  # An internal method for verifying that the PubControl instance has
  # not been closed via the close() method. If it has then an error
  # is raised.
  def verify_not_closed
    if @closed
      raise 'pubcontrol instance is closed'
    end
  end

  # Internal method to close clients.
  def close_clients
    verify_not_closed
    @clients.each do |pub|
      pub.close()
    end
    @closed = true
  end

  # Internal method to unregister from the list of pubcontrols.
  def unregister_pubcontrol
    @@lock.synchronize do
      @@pubcontrols.delete(self)
    end
  end

  # Internal method to unregister from the list of pubcontrols, used during
  # shutdown while class lock is held.
  def unregister_pubcontrol_locked
    @@pubcontrols.delete(self)
  end
end
