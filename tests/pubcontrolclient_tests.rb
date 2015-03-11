require 'format'
require 'item'
require 'jwt'
require 'thread'
require 'base64'
require 'pubcontrolclient'
require 'minitest/autorun'

def callback_test_method(result, error)
end

class TestFormatSubClass < Format
  def name
    return 'name'
  end

  def export
    return {'body' => 'bodyvalue'}
  end
end

class PccForPublishTesting < PubControlClient
  def set_test_instance(instance)
    @test_instance = instance
  end

  def pubcall(uri, auth_header, items)
    @test_instance.assert_equal(uri, 'uri')
    @test_instance.assert_equal(auth_header, 'Basic ' + Base64.encode64(
        'user:pass'))
    @test_instance.assert_equal(items, [{'name' => {'body' => 'bodyvalue'},
        'channel' => 'chann'}])
  end

  private 

  def queue_req(req)
    @test_instance.assert_equal(req[0], 'pub')
    @test_instance.assert_equal(req[1], 'uri')
    @test_instance.assert_equal(req[2], 'Basic ' + Base64.encode64(
        'user:pass'))
    @test_instance.assert_equal(req[3], {'name' => {'body' => 'bodyvalue'},
        'channel' => 'chann'})
    @test_instance.assert_equal(req[4], :callback_test_method)
  end

  def ensure_thread
    @ensure_thread_executed = true
  end
end

class TestPubControlClient < Minitest::Test
  def test_initialize
    pcc = PubControlClient.new('uri')
    assert_equal(pcc.instance_variable_get(:@uri), 'uri')
    assert_equal(pcc.instance_variable_get(:@thread), nil)
    assert_equal(pcc.instance_variable_get(:@thread_cond), nil)
    assert_equal(pcc.instance_variable_get(:@thread_mutex), nil)
    assert_equal(pcc.instance_variable_get(:@req_queue).length, 0)
    assert_equal(pcc.instance_variable_get(:@auth_basic_user), nil)
    assert_equal(pcc.instance_variable_get(:@auth_basic_pass), nil)
    assert_equal(pcc.instance_variable_get(:@auth_jwt_claim), nil)
    assert_equal(pcc.instance_variable_get(:@auth_jwt_key), nil)
    assert(!pcc.instance_variable_get(:@lock).nil?)
  end

  def test_set_auth_basic
    pcc = PubControlClient.new('uri')
    pcc.set_auth_basic('user', 'pass')
    assert_equal(pcc.instance_variable_get(:@auth_basic_user), 'user')
    assert_equal(pcc.instance_variable_get(:@auth_basic_pass), 'pass')
  end

  def test_set_auth_jwt
    pcc = PubControlClient.new('uri')
    pcc.set_auth_jwt('claim', 'key')
    assert_equal(pcc.instance_variable_get(:@auth_jwt_claim), 'claim')
    assert_equal(pcc.instance_variable_get(:@auth_jwt_key), 'key')
  end

  def test_ensure_thread
    pcc = PubControlClient.new('uri')
    pcc.send(:ensure_thread)
    assert(pcc.instance_variable_get(:@thread_mutex).is_a?(Mutex))
    assert(pcc.instance_variable_get(:@thread_cond).is_a?(ConditionVariable))
    assert(pcc.instance_variable_get(:@thread).is_a?(Thread))
  end

  def test_queue_req
    pcc = PubControlClient.new('uri')
    pcc.send(:ensure_thread)
    pcc.send(:queue_req, 'req')
    assert_equal(pcc.instance_variable_get(:@req_queue).front, 'req')
  end

  def test_gen_auth_header_basic
    pcc = PubControlClient.new('uri')
    pcc.set_auth_basic('user', 'pass')
    assert_equal(pcc.send(:gen_auth_header), 'Basic ' + Base64.encode64(
        'user:pass'))
  end

  def test_gen_auth_header_jwt
    pcc = PubControlClient.new('uri')
    pcc.set_auth_jwt({'iss' => 'hello', 'exp' => 1426106601},
        Base64.decode64('key'))
    assert_equal(pcc.send(:gen_auth_header), 'Bearer eyJ0eXAiOiJKV' +
        '1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJoZWxsbyIsImV4cCI6MTQyN' +
        'jEwNjYwMX0.92NIP0QPWbA-wRgsTA6zCwxejMgLkHep0S4UcAY3tN4')
  end

  def test_gen_auth_header_nil
    pcc = PubControlClient.new('uri')
    assert_equal(pcc.send(:gen_auth_header), nil)
  end

  def test_finish
    pcc = PubControlClient.new('uri')
    @thread_for_testing_finish_completed = false
    pcc.send(:ensure_thread)
    pcc.instance_variable_get(:@thread).terminate
    pcc.instance_variable_set(:@thread, Thread.new {
        thread_for_testing_finish })
    pcc.finish
    assert(@thread_for_testing_finish_completed)
    assert_equal(pcc.instance_variable_get(:@thread), nil)
    assert_equal(pcc.instance_variable_get(:@req_queue).front, ['stop'])
  end

  def thread_for_testing_finish
    sleep(1)
    @thread_for_testing_finish_completed = true
  end

  def test_timestamp_utcnow
    pcc = PubControlClient.new('uri')
    assert(Time.now.utc.to_i - PubControlClient.timestamp_utcnow < 2)
  end

  def test_publish
    pcc = PccForPublishTesting.new('uri')
    pcc.set_auth_basic('user', 'pass')
    pcc.set_test_instance(self)
    pcc.publish('chann', Item.new(TestFormatSubClass.new))
  end

  def test_publish_async
    pcc = PccForPublishTesting.new('uri')
    pcc.set_auth_basic('user', 'pass')
    pcc.set_test_instance(self)
    pcc.publish_async('chann', Item.new(TestFormatSubClass.new),
        :callback_test_method)
    assert(pcc.instance_variable_get(:@ensure_thread_executed))
  end
end
