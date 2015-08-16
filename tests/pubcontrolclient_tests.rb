require 'format'
require 'item'
require 'jwt'
require 'thread'
require 'base64'
require 'pubcontrolclient'
require 'minitest/autorun'
require 'net/http'

class TestFormatSubClass < Format
  def name
    return 'name'
  end

  def export
    return {'body' => 'bodyvalue'}
  end
end

class PubControlClientForTesting < PubControlClient
  def set_test_instance(instance)
    @test_instance = instance
  end
end

class PccForPublishTesting < PubControlClientForTesting
  def pubcall(uri, auth_header, items)
    @test_instance.assert_equal(uri, 'uri')
    @test_instance.assert_equal(auth_header, 'Basic ' + Base64.encode64(
        'user:pass'))
    @test_instance.assert_equal(items, [{'name' => {'body' => 'bodyvalue'},
        'channel' => 'chann'}])
  end

  def queue_req(req)
    @test_instance.assert_equal(req[0], 'pub')
    @test_instance.assert_equal(req[1], 'uri')
    @test_instance.assert_equal(req[2], 'Basic ' + Base64.encode64(
        'user:pass'))
    @test_instance.assert_equal(req[3], [{'name' => {'body' => 'bodyvalue'},
        'channel' => 'chann'}])
    @test_instance.assert_equal(req[4], 'callback')
  end

  def ensure_thread
    @ensure_thread_executed = true
  end
end

class PccForPublishTesting2 < PubControlClientForTesting
  def pubcall(uri, auth_header, items)
    @test_instance.assert_equal(uri, 'uri')
    @test_instance.assert_equal(auth_header, 'Basic ' + Base64.encode64(
        'user:pass'))
    @test_instance.assert_equal(items, [{'name' => {'body' => 'bodyvalue'},
        'channel' => 'chann'}, {'name' => {'body' => 'bodyvalue'},
        'channel' => 'chann2'}])
  end

  def queue_req(req)
    @test_instance.assert_equal(req[0], 'pub')
    @test_instance.assert_equal(req[1], 'uri')
    @test_instance.assert_equal(req[2], 'Basic ' + Base64.encode64(
        'user:pass'))
    @test_instance.assert_equal(req[3], [{'name' => {'body' => 'bodyvalue'},
        'channel' => 'chann'}, {'name' => {'body' => 'bodyvalue'},
        'channel' => 'chann2'}])
    @test_instance.assert_equal(req[4], 'callback')
  end

  def ensure_thread
    @ensure_thread_executed = true
  end
end

class PccForPubCallTesting < PubControlClientForTesting
  def set_params(uri, use_ssl, auth, result_failure = false)
    @http_uri = uri
    @http_use_ssl = use_ssl
    @http_auth = auth
    @http_result_failure = result_failure
  end

  def make_http_request(uri, use_ssl, request)
    @test_instance.assert_equal(uri, URI(@http_uri + '/publish/'))
    @test_instance.assert_equal(use_ssl, @http_use_ssl)
    @test_instance.assert_equal(request.body, {'items' => 
        [{'name' => {'body' => 'bodyvalue'}, 'channel' => 'chann'}]}.to_json)
    @test_instance.assert_equal(request['Authorization'], @http_auth)
    @test_instance.assert_equal(request['Content-Type'], 'application/json')
    if @http_result_failure
      return Net::HTTPServerError.new(1.0, 400,
          'Bad request')
    end
    return Net::HTTPSuccess.new(1.0, 200, 'Ok')
  end
end

class PccForPubBatchTesting < PubControlClientForTesting
  def set_params(result_failure, num_callbacks)
    @req_index = 0
    @num_callbacks = num_callbacks
    @http_result_failure = result_failure
  end

  def pubcall(uri, auth_header, items)
    @test_instance.assert_equal(uri, 'uri')
    @test_instance.assert_equal(auth_header, 'Basic ' + Base64.encode64(
        'user:pass' + @req_index.to_s))
    items_to_compare_with = []
    export = Item.new(TestFormatSubClass.new).export
    export['channel'] = 'chann'
    (0..@num_callbacks - 1).each do |n|
      items_to_compare_with.push(export.clone)
    end
    @req_index += 1
    @test_instance.assert_equal(items, items_to_compare_with)
    if @http_result_failure
      raise 'error message'
    end
  end
end

class PccForPubBatchTesting2 < PubControlClientForTesting
  def set_params(result_failure, num_callbacks)
    @req_index = 0
    @num_callbacks = num_callbacks
    @http_result_failure = result_failure
  end

  def pubcall(uri, auth_header, items)
    @test_instance.assert_equal(uri, 'uri')
    @test_instance.assert_equal(auth_header, 'Basic ' + Base64.encode64(
        'user:pass' + @req_index.to_s))
    items_to_compare_with = []
    export = Item.new(TestFormatSubClass.new).export
    export['channel'] = 'chann'
    export2 = Item.new(TestFormatSubClass.new).export
    export2['channel'] = 'chann2'
    (0..@num_callbacks - 1).each do |n|
      items_to_compare_with.push(export.clone)
      items_to_compare_with.push(export2.clone)
    end
    @req_index += 1
    @test_instance.assert_equal(items, items_to_compare_with)
    if @http_result_failure
      raise 'error message'
    end
  end
end

class PccForPubWorkerTesting < PubControlClientForTesting
  attr_accessor :req_index

  def set_params
    @req_index = 0
  end

  def pubbatch(reqs)
    @test_instance.assert(reqs.length <= 10, 'reqs.length == ' +
        reqs.length.to_s)
    reqs.each do |req|
      @test_instance.assert_equal(req[0], 'uri')
      @test_instance.assert_equal(req[1], 'Basic ' + Base64.encode64(
          'user:pass' + @req_index.to_s))
      export = Item.new(TestFormatSubClass.new).export
      export['channel'] = 'chann'
      @test_instance.assert_equal(req[2], export)
      @test_instance.assert_equal(req[3], 'callback')
      @req_index += 1
    end     
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
    pcc = PccForPublishTesting2.new('uri')
    pcc.set_auth_basic('user', 'pass')
    pcc.set_test_instance(self)
    pcc.publish(['chann', 'chann2'], Item.new(TestFormatSubClass.new))
  end

  def test_publish_async
    pcc = PccForPublishTesting.new('uri')
    pcc.set_auth_basic('user', 'pass')
    pcc.set_test_instance(self)
    pcc.publish_async('chann', Item.new(TestFormatSubClass.new), 'callback')
    assert(pcc.instance_variable_get(:@ensure_thread_executed))
    pcc = PccForPublishTesting2.new('uri')
    pcc.set_auth_basic('user', 'pass')
    pcc.set_test_instance(self)
    pcc.publish_async(['chann', 'chann2'], Item.new(TestFormatSubClass.new), 'callback')
    assert(pcc.instance_variable_get(:@ensure_thread_executed))
  end

  def test_pubcall_success_http
    pcc = PccForPubCallTesting.new('uri')
    pcc.set_auth_basic('user', 'pass')
    pcc.set_params('http://localhost:8080', false, 'Basic ' +
        Base64.encode64('user:pass'))
    pcc.set_test_instance(self)
    pcc.send(:pubcall, 'http://localhost:8080', 'Basic ' +
        Base64.encode64('user:pass'), [{'name' => {'body' => 'bodyvalue'},
        'channel' => 'chann'}])
  end

  def test_pubcall_success_https
    pcc = PccForPubCallTesting.new('uri')
    pcc.set_auth_jwt({'iss' => 'hello', 'exp' => 1426106601},
        Base64.decode64('key'))
    pcc.set_test_instance(self)
    pcc.set_params('https://localhost:8080', true, 'Bearer eyJ0eXAiOiJKV' +
        '1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJoZWxsbyIsImV4cCI6MTQyN' +
        'jEwNjYwMX0.92NIP0QPWbA-wRgsTA6zCwxejMgLkHep0S4UcAY3tN4')
    pcc.send(:pubcall, 'https://localhost:8080', 'Bearer eyJ0eXAiOiJKV' +
        '1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJoZWxsbyIsImV4cCI6MTQyN' +
        'jEwNjYwMX0.92NIP0QPWbA-wRgsTA6zCwxejMgLkHep0S4UcAY3tN4',
        [{'name' => {'body' => 'bodyvalue'}, 'channel' => 'chann'}])
  end

  def test_pubcall_failure
    pcc = PccForPubCallTesting.new('uri')
    pcc.set_params('http://localhost:8080', false, nil, true)
    pcc.set_test_instance(self)
    begin
      pcc.send(:pubcall, 'http://localhost:8080', nil, [{'name' =>
          {'body' => 'bodyvalue'}, 'channel' => 'chann'}])
      assert(false, 'HTTPServerError not raised')
    rescue => e
      assert(e.message.index('HTTPServerError'))
      assert(e.message.index('Bad request'))
    end
  end

  def test_pubbatch_success
    pcc = PccForPubBatchTesting.new('uri')
    pcc.set_test_instance(self)
    @result_expected = true
    @message_expected = ''
    @num_cbs_expected = 5
    pcc.set_params(nil, @num_cbs_expected)
    reqs = []
    export = Item.new(TestFormatSubClass.new).export
    export['channel'] = 'chann'
    (0..@num_cbs_expected - 1).each do |n|
      reqs.push(['uri', 'Basic ' + Base64.encode64('user:pass' + n.to_s),
          export, method(:pubbatch_callback)])
    end
    pcc.send(:pubbatch, reqs)
    assert_equal(@num_cbs_expected, 0)
  end

  def test_pubbatch_success2
    pcc = PccForPubBatchTesting2.new('uri')
    pcc.set_test_instance(self)
    @result_expected = true
    @message_expected = ''
    @num_cbs_expected = 5
    pcc.set_params(nil, @num_cbs_expected)
    reqs = []
    export = Item.new(TestFormatSubClass.new).export
    export['channel'] = 'chann'
    export2 = Item.new(TestFormatSubClass.new).export
    export2['channel'] = 'chann2'
    (0..@num_cbs_expected - 1).each do |n|
      reqs.push(['uri', 'Basic ' + Base64.encode64('user:pass' + n.to_s),
          [export, export2], method(:pubbatch_callback)])
    end
    pcc.send(:pubbatch, reqs)
    assert_equal(@num_cbs_expected, 0)
  end

  def test_pubbatch_failure
    pcc = PccForPubBatchTesting.new('uri')
    pcc.set_test_instance(self)
    @result_expected = false
    @message_expected = 'error message'
    @num_cbs_expected = 5
    pcc.set_params(true, @num_cbs_expected)
    reqs = []
    export = Item.new(TestFormatSubClass.new).export
    export['channel'] = 'chann'
    (0..@num_cbs_expected - 1).each do |n|
      reqs.push(['uri', 'Basic ' + Base64.encode64('user:pass' + n.to_s),
          export, method(:pubbatch_callback)])
    end
    pcc.send(:pubbatch, reqs)
    assert_equal(@num_cbs_expected, 0)
  end

  def pubbatch_callback(result, message)
    @num_cbs_expected -= 1
    assert_equal(result, @result_expected)
    assert_equal(message, @message_expected)
  end

  def test_pubworker
    pcc = PccForPubWorkerTesting.new('uri')
    pcc.set_test_instance(self)
    pcc.set_params
    pcc.send(:ensure_thread)
    export = Item.new(TestFormatSubClass.new).export
    export['channel'] = 'chann'
    (0..500 - 1).each do |n|
      pcc.instance_variable_get(:@req_queue).push_back(['pub', 'uri',
          'Basic ' + Base64.encode64('user:pass' + n.to_s), export,
          'callback'])
    end
    pcc.finish
    assert_equal(pcc.req_index, 500)
  end

  def test_pubworker_stop
    pcc = PccForPubWorkerTesting.new('uri')
    pcc.set_test_instance(self)
    pcc.set_params
    pcc.send(:ensure_thread)
    export = Item.new(TestFormatSubClass.new).export
    export['channel'] = 'chann'
    (0..500 - 1).each do |n|
      if n == 250
        pcc.instance_variable_get(:@req_queue).push_back(['stop'])
      else
        pcc.instance_variable_get(:@req_queue).push_back(['pub', 'uri',
            'Basic ' + Base64.encode64('user:pass' + n.to_s), export,
            'callback'])
      end
    end
    pcc.finish
    assert_equal(pcc.req_index, 250)
  end
end
