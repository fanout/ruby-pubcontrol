ruby-pubcontrol
===============

Author: Konstantin Bokarius <bokarius@comcast.net>

A Ruby convenience library for publishing messages using the EPCP protocol.

License
-------

ruby-pubcontrol is offered under the MIT license. See the LICENSE file.

Installation
------------

```sh
gem install pubcontrol
```

Usage
-----

```Ruby
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
  if result
    puts 'Publish successful'
  else
    puts 'Publish failed with message: ' + message.to_s
  end
end

pubcontrol = PubControl.new('https://api.fanout.io/realm/<myrealm>')
pubcontrol.set_auth_jwt({'iss' => '<myrealm>'},
    Base64.decode64('<myrealmkey>'))
pubcontrol.publish('<channel>', Item.new(HttpResponseFormat.new(
    'Test publish!\n')))
pubcontrol.publish_async('<channel>', Item.new(HttpResponseFormat.new(
    'Test async publish!\n')), method(:callback))

pubcontrolset = PubControlSet.new
pubcontrolset.apply_config([{'uri' => 
    'https://api.fanout.io/realm/<myrealm>', 
    'iss' => '<myrealm>', 'key' => Base64.decode64('<myrealmkey>')}])
pubcontrolset.publish('<channel>', Item.new(HttpResponseFormat.new(
    'PubControlSet test publish!\n')), false, method(:callback))
```
