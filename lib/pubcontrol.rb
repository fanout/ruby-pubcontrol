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

# The PubControl class allows a consumer to manage a set of publishing
# endpoints and to publish to all of those endpoints via a single publish
# or publish_async method call. A PubControl instance can be configured
# either using a hash or array of hashes containing configuration information
# or by manually adding PubControlClient instances.
class PubControl

  # Initialize with or without a configuration. A configuration can be applied
  # after initialization via the apply_config method.
  def initialize(config=nil)
    @clients = Array.new
    if !config.nil?
      apply_config(config)
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

  # The finish method is a blocking method that ensures that all asynchronous
  # publishing is complete for all of the configured PubControlClient
  # instances prior to returning and allowing the consumer to proceed.
  def finish
    @clients.each do |pub|
      pub.finish
    end
  end

  # The synchronous publish method for publishing the specified item to the
  # specified channel for all of the configured PubControlClient instances.
  def publish(channel, item)
    @clients.each do |pub|
      pub.publish(channel, item)
    end
  end

  # The asynchronous publish method for publishing the specified item to the
  # specified channel on the configured endpoint. The callback method is
  # optional and will be passed the publishing results after publishing is
  # complete. Note that a failure to publish in any of the configured
  # PubControlClient instances will result in a failure result being passed
  # to the callback method along with the first encountered error message.
  def publish_async(channel, item, callback=nil)
    cb = nil
    if !callback.nil?
      cb = PubControlClientCallbackHandler.new(@clients.length, callback).
          handler_method_symbol
    end
    @clients.each do |pub|
      pub.publish_async(channel, item, cb)
    end
  end
end
