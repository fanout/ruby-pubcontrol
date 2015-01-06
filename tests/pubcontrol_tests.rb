require 'pubcontrol'

class HttpResponseFormat < Format
  def initialize(body)
    @body = body
  end

  def name
    return 'http-response'
  end

  def export
    return {'body' => @body}
  end
end

def callback(result, message)
  if !result
    puts 'Publish failed with message: ' + message.to_s
  end    
end

config = {'uri' => ENV['FANOUT_URI'],
    'iss' => ENV['FANOUT_REALM'], 'key' => 
    Base64.decode64(ENV['FANOUT_KEY'])}
pub = PubControl.new(config)
pub.publish('test', Item.new(HttpResponseFormat.new('Test publish!\n')))

pub = PubControl.new()
pubclient = PubControlClient.new(ENV['FANOUT_URI'])
pubclient.set_auth_jwt({'iss' => ENV['FANOUT_REALM']}, 
    Base64.decode64(ENV['FANOUT_KEY']))
pub.add_client(pubclient)
pubclient = PubControlClient.new(ENV['FANOUT_URI'])
pubclient.set_auth_jwt({'iss' => ENV['FANOUT_REALM']}, 
    Base64.decode64(ENV['FANOUT_KEY']))
pub.add_client(pubclient)

index = 0
while index < 20 do
  pub.publish_async('test', Item.new(HttpResponseFormat.new(
      'Test async publish: ' + index.to_s)), method(:callback))
  index += 1
end
pub.finish
pub.remove_all_clients
