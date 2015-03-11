require 'format'
require 'item'
require 'pubcontrolclient'
require 'minitest/autorun'

class TestFormatSubClass < Format
  def name
    return 'name'
  end

  def export
    return {'body' => 'bodyvalue'}
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
end
