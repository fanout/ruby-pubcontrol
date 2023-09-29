require 'format'
require 'item'
require 'pubcontrol'
require 'minitest/autorun'

class PubControlClientTestClass
  attr_accessor :was_finish_called
  attr_accessor :publish_channel
  attr_accessor :publish_item
  attr_accessor :publish_callback

  def initialize
    @was_finish_called = false
    @publish_channel = nil
    @publish_item = nil
    @publish_callback = nil
  end

  def finish
    @was_finish_called = true
  end

  def close
    @was_finish_called = true
  end

  def wait_all_sent
    @was_finish_called = true
  end

  def publish(channel, item)
    @publish_channel = channel
    @publish_item = item
  end

  def publish_async(channel, item, callback=nil)
    @publish_channel = channel
    @publish_item = item
    @publish_callback = callback
  end
end

class TestPubControl < Minitest::Test
  def test_initialize
    pc = PubControl.new
    assert_equal(pc.instance_variable_get(:@clients).length, 0)
    config = {'uri' => 'uri', 'iss' => 'iss', 'key' => 'key'}
    pc = PubControl.new(config)
    assert_equal(pc.instance_variable_get(:@clients).length, 1)
    config = [{'uri' => 'uri', 'iss' => 'iss', 'key' => 'key'},
        {'uri' => 'uri', 'iss' => 'iss', 'key' => 'key'}]
    pc = PubControl.new(config)
    assert_equal(pc.instance_variable_get(:@clients).length, 2)
    config = {'uri' => 'uri', 'key' => 'key'}
    pc = PubControl.new(config)
    assert_equal(pc.instance_variable_get(:@clients).length, 1)
  end

  def test_remove_all_clients
    pc = PubControl.new
    pc.instance_variable_get(:@clients).push('client')
    pc.remove_all_clients
    assert_equal(pc.instance_variable_get(:@clients).length, 0)
  end

  def test_add_client
    pc = PubControl.new
    pc.add_client('client')
    assert_equal(pc.instance_variable_get(:@clients)[0], 'client')
  end

  def test_apply_config
    pc = PubControl.new
    config = {'uri' => 'uri'}
    pc.apply_config(config)
    assert_equal(pc.instance_variable_get(
        :@clients)[0].instance_variable_get(:@uri), 'uri')
    pc = PubControl.new
    config = [{'uri' => 'uri'},
        {'uri' => 'uri1', 'iss' => 'iss1', 'key' => 'key1'},
        {'uri' => 'uri2', 'key' => 'key_bearer'}]
    pc.apply_config(config)
    assert_equal(pc.instance_variable_get(
        :@clients)[0].instance_variable_get(:@uri), 'uri')
    assert_equal(pc.instance_variable_get(
        :@clients)[0].instance_variable_get(:@auth_jwt_claim), nil)
    assert_equal(pc.instance_variable_get(
        :@clients)[0].instance_variable_get(:@auth_jwt_key), nil)
    assert_equal(pc.instance_variable_get(
        :@clients)[1].instance_variable_get(:@uri), 'uri1')
    assert_equal(pc.instance_variable_get(
        :@clients)[1].instance_variable_get(:@auth_jwt_claim),
        {'iss' => 'iss1'})
    assert_equal(pc.instance_variable_get(
        :@clients)[1].instance_variable_get(:@auth_jwt_key), 'key1')
    assert_equal(pc.instance_variable_get(
        :@clients)[2].instance_variable_get(:@uri), 'uri2')
    assert_equal(pc.instance_variable_get(
        :@clients)[2].instance_variable_get(:@auth_bearer_key), 'key_bearer')
  end

  def test_finish
    pc = PubControl.new
    pccs = []
    (0..3).each do |n|
      pcc = PubControlClientTestClass.new
      pccs.push(pcc)
      pc.add_client(pcc)
    end
    pc.finish
    (0..3).each do |n|
      assert(pccs[n].was_finish_called)
    end
  end

  def test_publish
    pc = PubControl.new
    pccs = []
    (0..3).each do |n|
      pcc = PubControlClientTestClass.new
      pccs.push(pcc)
      pc.add_client(pcc)
    end
    pc.publish('channel', 'item')
    (0..3).each do |n|
      assert_equal(pccs[n].publish_channel, 'channel')
      assert_equal(pccs[n].publish_item, 'item')
    end
    pc = PubControl.new
    pccs = []
    (0..3).each do |n|
      pcc = PubControlClientTestClass.new
      pccs.push(pcc)
      pc.add_client(pcc)
    end
    pc.publish(['channel', 'channel2'], 'item')
    (0..3).each do |n|
      assert_equal(pccs[n].publish_channel, ['channel', 'channel2'])
      assert_equal(pccs[n].publish_item, 'item')
    end
  end

  def test_publish_async_without_callback
    pc = PubControl.new
    pccs = []
    (0..3).each do |n|
      pcc = PubControlClientTestClass.new
      pccs.push(pcc)
      pc.add_client(pcc)
    end
    pc.publish_async('channel', 'item')
    (0..3).each do |n|
      assert_equal(pccs[n].publish_channel, 'channel')
      assert_equal(pccs[n].publish_item, 'item')
      assert_equal(pccs[n].publish_callback, nil)
    end
    pc = PubControl.new
    pccs = []
    (0..3).each do |n|
      pcc = PubControlClientTestClass.new
      pccs.push(pcc)
      pc.add_client(pcc)
    end
    pc.publish_async(['channel', 'channel2'], 'item')
    (0..3).each do |n|
      assert_equal(pccs[n].publish_channel, ['channel', 'channel2'])
      assert_equal(pccs[n].publish_item, 'item')
      assert_equal(pccs[n].publish_callback, nil)
    end
  end

  def callback_for_testing(result, error)
    assert_equal(@has_callback_been_called, false)
    assert_equal(result, false)
    assert_equal(error, 'error')
    @has_callback_been_called = true
  end

  def test_publish_async_with_callback
    @has_callback_been_called = false
    pc = PubControl.new
    pccs = []
    (0..3).each do |n|
      pcc = PubControlClientTestClass.new
      pccs.push(pcc)
      pc.add_client(pcc)
    end
    pc.publish_async('channel', 'item', method(:callback_for_testing))
    (0..3).each do |n|
      assert_equal(pccs[n].publish_channel, 'channel')
      assert_equal(pccs[n].publish_item, 'item')
      pccs[n].publish_callback.call(false, 'error')
    end
    assert(@has_callback_been_called)
  end
end
