#    pubcontrolclient.rb
#    ~~~~~~~~~
#    This module implements the PubControlClient class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require 'algorithms'
require 'thread'
require 'base64'
require 'jwt'
require 'json'
require 'net/http/persistent'
require_relative 'item.rb'

# The PubControlClient class allows consumers to publish either synchronously 
# or asynchronously to an endpoint of their choice. The consumer wraps a Format
# class instance in an Item class instance and passes that to the publish
# methods. The async publish method has an optional callback parameter that
# is called after the publishing is complete to notify the consumer of the
# result.
class PubControlClient
  attr_accessor :req_queue

  # Initialize this class with a URL representing the publishing endpoint.
  def initialize(uri)
    @uri = uri
    @lock = Mutex.new
    @thread = nil
    @thread_cond = nil
    @thread_mutex = nil
    @req_queue = Containers::Deque.new
    @auth_basic_user = nil
    @auth_basic_pass = nil
    @auth_jwt_claim = nil
    @auth_jwt_key = nil
    @http = Net::HTTP::Persistent.new @object_id.to_s
    @http.open_timeout = 10
    @http.read_timeout = 10
  end

  # Call this method and pass a username and password to use basic
  # authentication with the configured endpoint.
  def set_auth_basic(username, password)
    @lock.synchronize do
      @auth_basic_user = username
      @auth_basic_pass = password
    end
  end

  # Call this method and pass a claim and key to use JWT authentication
  # with the configured endpoint.
  def set_auth_jwt(claim, key)
    @lock.synchronize do
      @auth_jwt_claim = claim
      @auth_jwt_key = key
    end
  end

  # The synchronous publish method for publishing the specified item to the
  # specified channels on the configured endpoint.
  def publish(channels, item)
    exports = [channels].flatten.map do |channel|
      export            = item.export
      export['channel'] = channel
      export
    end
    uri   = nil
    auth  = nil
    @lock.synchronize do
      uri   = @uri
      auth  = gen_auth_header
    end
    pubcall(uri, auth, exports)
  end

  # The asynchronous publish method for publishing the specified item to the
  # specified channels on the configured endpoint. The callback method is
  # optional and will be passed the publishing results after publishing is
  # complete.
  def publish_async(channels, item, callback=nil)
    exports = [channels].flatten.map do |channel|
      export            = item.export
      export['channel'] = channel
      export
    end
    uri   = nil
    auth  = nil
    @lock.synchronize do
      uri   = @uri
      auth  = gen_auth_header
      ensure_thread
    end
    queue_req(['pub', uri, auth, exports, callback])
  end

  # This method is a blocking method that ensures that all asynchronous
  # publishing is complete prior to returning and allowing the consumer to 
  # proceed.
  def wait_all_sent
    @lock.synchronize do
      if !@thread.nil?
        queue_req(['stop'])
        @thread.join
        @thread = nil
      end
    end
  end

  # DEPRECATED: The finish method is now deprecated in favor of the more
  # descriptive wait_all_sent method.
  def finish
    wait_all_sent
  end

  # This method closes the PubControlClient instance by ensuring all pending
  # data is sent and any open connections are closed.
  def close
    wait_all_sent
    @http.shutdown
  end

  # A helper method for returning the current UNIX UTC timestamp.
  def self.timestamp_utcnow
    return Time.now.utc.to_i
  end

  private

  # An internal method for preparing the HTTP POST request for publishing
  # data to the endpoint. This method accepts the URI endpoint, authorization
  # header, and a list of items to publish.
  def pubcall(uri, auth_header, items)
    if uri.to_s[-1] != '/'
      uri = uri.to_s + '/'
    end
    uri = URI(uri + 'publish/')
    content = Hash.new
    content['items'] = items
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = content.to_json
    if !auth_header.nil?
      request['Authorization'] = auth_header
    end
    request['Content-Type'] = 'application/json'
    response = make_http_request(uri, request)
    if !response.kind_of? Net::HTTPSuccess
      raise 'failed to publish: ' + response.class.to_s + ' ' +
          response.message + ' ' + response.body.dump
    end
  end

  # An internal method for making the specified HTTP request to the
  # specified URI.
  def make_http_request(uri, request)
    response = @http.request uri, request
    return response
  end

  # An internal method for publishing a batch of requests. The requests are
  # parsed for the URI, authorization header, and each request is published
  # to the endpoint. After all publishing is complete, each callback
  # corresponding to each request is called (if a callback was originally
  # provided for that request) and passed a result indicating whether that
  # request was successfully published.
  def pubbatch(reqs)
    raise 'reqs length == 0' unless reqs.length > 0
    uri = reqs[0][0]
    auth_header = reqs[0][1]
    items = Array.new
    callbacks = Array.new
    reqs.each do |req|
      if req[2].is_a? Array
        items = items + req[2]
      else
        items.push(req[2])
      end
      callbacks.push(req[3])
    end
    begin
      pubcall(uri, auth_header, items)
      result = [true, '']
    rescue => e
      result = [false, e.message]
    end
    callbacks.each do |callback|
      if !callback.nil?
        callback.call(result[0], result[1])
      end
    end
  end

  # An internal method that is meant to run as a separate thread and process
  # asynchronous publishing requests. The method runs continously and
  # publishes requests in batches containing a maximum of 10 requests. The
  # method completes and the thread is terminated only when a 'stop' command
  # is provided in the request queue.
  def pubworker
    quit = false
    while !quit do
      @thread_mutex.lock
      if @req_queue.length == 0
        @thread_cond.wait(@thread_mutex)
        if @req_queue.length == 0
          @thread_mutex.unlock
          next
        end
      end
      reqs = Array.new
      while @req_queue.length > 0 and reqs.length < 10 do
        m = @req_queue.pop_front
        if m[0] == 'stop'
          quit = true
          break
        end
        reqs.push([m[1], m[2], m[3], m[4]])
      end
      @thread_mutex.unlock
      if reqs.length > 0
        pubbatch(reqs)
      end
    end
  end

  # An internal method used to generate an authorization header. The
  # authorization header is generated based on whether basic or JWT
  # authorization information was provided via the publicly accessible
  # 'set_*_auth' methods defined above.
  def gen_auth_header
    if !@auth_basic_user.nil?
      return 'Basic ' + Base64.encode64(
          "#{@auth_basic_user}:#{@auth_basic_pass}")
    elsif !@auth_jwt_claim.nil?
      if !@auth_jwt_claim.key?('exp')
        claim = @auth_jwt_claim.clone
        claim['exp'] = PubControlClient.timestamp_utcnow + 3600
      else
        claim = @auth_jwt_claim
      end
      return 'Bearer ' + JWT.encode(claim, @auth_jwt_key)
    else
      return nil
    end
  end

  # An internal method that ensures that asynchronous publish calls are
  # properly processed. This method initializes the required class fields,
  # starts the pubworker worker thread, and is meant to execute only when
  # the consumer makes an asynchronous publish call.
  def ensure_thread
    if @thread.nil?
      @thread_cond = ConditionVariable.new
      @thread_mutex = Mutex.new
      @thread = Thread.new { pubworker }
    end
  end

  # An internal method for adding an asynchronous publish request to the 
  # publishing queue. This method will also activate the pubworker worker
  # thread to make sure that it process any and all requests added to
  # the queue.
  def queue_req(req)
    @thread_mutex.lock
    @req_queue.push_back(req)
    @thread_cond.signal
    @thread_mutex.unlock
  end
end
