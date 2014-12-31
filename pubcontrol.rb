require 'algorithms'
require 'thread'
require 'base64'
require 'jwt'
require 'json'
require 'net/http'

class Format
	def name
		raise NotImplementedError
    end

	def export
		raise NotImplementedError
	end
end

class Item
	def initialize(formats, id=nil, prev_id=nil)
		@id = id
		@prev_id = prev_id
		if formats.is_a? Format
			formats = [formats]
		end
		@formats = formats
	end

	def export
		out = Hash.new
		if !@id.nil?
			out['id'] = @id
		end
		if !@prev_id.nil?
			out['prev-id'] = @prev_id
		end
		@formats.each do |format|
			out[format.name] = format.export
		end
		return out
	end
end

class PubControl
	attr_accessor :req_queue

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
	end

	def set_auth_basic(username, password)
		@lock.synchronize do
			@auth_basic_user = username
			@auth_basic_pass = password
		end
	end

	def set_auth_jwt(claim, key)
		@lock.synchronize do
			@auth_jwt_claim = claim
			@auth_jwt_key = key
		end
	end

	def publish(channel, item)
		export = item.export
		export['channel'] = channel
		uri = nil
		auth = nil
		@lock.synchronize do
			uri = @uri
			auth = gen_auth_header
		end
		PubControl.pubcall(uri, auth, [export])
	end

	def publish_async(channel, item, callback=nil)
		export = item.export
		export['channel'] = channel
		uri = nil
		auth = nil
		@lock.synchronize do
			uri = @uri
			auth = gen_auth_header
			ensure_thread
		end
		queue_req(['pub', uri, auth, export, callback])
	end

	def finish
		@lock.synchronize do
			if !@thread.nil?
				queue_req(['stop'])
				@thread.join
				@thread = nil
			end
		end
	end

	def gen_auth_header
		if !@auth_basic_user.nil?
			return 'Basic ' + Base64.encode64(
					'#{@auth_basic_user}:#{@auth_basic_pass}')
		elsif !@auth_jwt_claim.nil?
			if !@auth_jwt_claim.has_key?('exp')
				claim = @auth_jwt_claim.clone
				claim['exp'] = PubControl.timestamp_utcnow + 3600
			else
				claim = @auth_jwt_claim
			end
			return 'Bearer ' + JWT.encode(claim, @auth_jwt_key)
		else
			return None
		end
	end

	def ensure_thread
		if @thread.nil?
			@thread_cond = ConditionVariable.new
			@thread_mutex = Mutex.new
			@thread = Thread.new { pubworker }
			# REVIEW: Ruby threads are daemonic by default 
			#@thread.daemon = True
		end
	end

	def queue_req(req)
		# REVIEW: thread condition implementation
		@thread_mutex.synchronize {
			@req_queue.push_back(req)
			@thread_cond.signal
		}
	end

	def self.pubcall(uri, auth_header, items)
		uri = URI(uri + '/publish/')
		content = Hash.new
		content['items'] = items
		# REVIEW: POST implementation
		request = Net::HTTP::Post.new(uri.path)
		# REVIEW: Ruby strings are unicode by default
		# is forcing the encoding to UTF-8 necessary?
		request.body = content.to_json.force_encoding("UTF-8")
		if !auth_header.nil?
			request['Authorization'] = auth_header
		end
		request['Content-Type'] = 'application/json'
		response = Net::HTTP.start(uri.host, use_ssl: true) do |http|
			http.request(request)
		end
		# REVIEW: HTTPSuccess does not include 3xx status codes.
		if !response.kind_of? Net::HTTPSuccess
			raise 'failed to publish: ' + response.class.to_s + ' ' +
					response.message
		end
	end

	def self.pubbatch(reqs)
		raise "reqs length == 0" unless reqs.length > 0
		uri = reqs[0][0]
		auth_header = reqs[0][1]
		items = Array.new
		callbacks = Array.new
		reqs.each do |req|
			items.push(req[2])
			callbacks.push(req[3])
		end
		begin	
			PubControl.pubcall(uri, auth_header, items)
			result = [True, '']
		rescue => e
			result = [False, e.message]
		end
		callbacks.each do |callback|
			if !callback.nil?
				callback(result[0], result[1])
			end
		end
	end

	def self.pubworker
		quit = False
		while !quit do
			@thread_mutex.synchronize do
				if @req_queue.length == 0
					@thread_cond.wait(@thread_mutex)
					if @req_queue.length == 0
						@thread_cond.release
						next
					end
				end
				reqs = Array.new
				while @req_queue.length > 0 and reqs.length < 10 do
					m = self.req_queue.pop_front
					if m[0] == 'stop'
						quit = True
						break
					end
					reqs.push([m[1], m[2], m[3], m[4]])
				end
				@thread_cond.release
				if reqs.length > 0
					PubControl.pubbatch(reqs)
				end
			end
		end
	end

	def self.timestamp_utcnow
		# REVIEW: gmtime Ruby implementation
		return Time.now.utc.to_i
	end

	private :queue_req
	private :ensure_thread
	private :gen_auth_header
end
