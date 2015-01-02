#    pubcontrolset.rb
#    ~~~~~~~~~
#    This module implements the PubControlSet class.
#    :copyright: (c) 2014 by Konstantin Bokarius.
#    :license: MIT, see LICENSE for more details.

require_relative 'pubcontrol.rb'
require_relative 'pccbhandler.rb'

class PubControlSet
  def initialize
    @pubs = Array.new
    at_exit { finish }
  end

  def clear
    @pubs = Array.new
  end

  def add(pub)
    @pubs.push(pub)
  end

  def apply_config(config)
    config.each do |entry|
      pub = PubControl.new(entry['uri'])
      if entry.key?('iss')
        pub.set_auth_jwt({'iss' => entry['iss']}, entry['key'])
      end
      @pubs.push(pub)
    end
  end

  def apply_grip_config(config)
    config.each do |entry|
      if !entry.key?('control_uri')
        next
      end
      pub = PubControl.new(entry['control_uri'])
      if !entry.key?('control_iss')
        pub.set_auth_jwt({'iss' => entry['control_iss']}, entry['key'])
      end
      @pubs.push(pub)
    end
  end

  def publish(channel, item, blocking=false, callback=nil)
    if blocking
      @pubs.each do |pub|
        pub.publish(channel, item)
      end
    else
      cb = nil
      if !callback.nil?
        cb = PubControlCallbackHandler.new(@pubs.length, callback).
            handler_method_symbol
      end
      @pubs.each do |pub|
        pub.publish_async(channel, item, cb)
      end
    end
  end

  private

  def finish
    @pubs.each do |pub|
      pub.finish
    end
  end
end
