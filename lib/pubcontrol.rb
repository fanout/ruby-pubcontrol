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

class PubControl
  def initialize(config=nil)
    @clients = Array.new
    if !config.nil?
      apply_config(config)
    end
  end

  def remove_all_clients
    @clients = Array.new
  end

  def add_client(client)
    @clients.push(client)
  end

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

  def finish
    @clients.each do |pub|
      pub.finish
    end
  end

  def publish(channel, item)
    @clients.each do |pub|
      pub.publish(channel, item)
    end
  end

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
