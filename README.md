ruby-pubcontrol
===============

Author: Konstantin Bokarius <bokarius@comcast.net>
Mailing List: http://lists.fanout.io/listinfo.cgi/fanout-users-fanout.io

A convenience library for Ruby implementing the EPCP protocol.

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

pub = PubControl.new('https://api.fanout.io/realm/<myrealm>')
pub.set_auth_jwt({'iss' => '<myrealm>'},
    Base64.decode64('<myrealmkey>'))
pub.publish('test', Item.new(HttpResponseFormat.new('Test publish!\n')))
pub.publish_async('test', Item.new(HttpResponseFormat.new('Test async publish!\n')),
    method(:callback))

pubcs = PubControlSet.new
pubcs.apply_config([{'uri' => 'https://api.fanout.io/realm/<myrealm>', 
    'iss' => '<myrealm>', 'key' => Base64.decode64('<myrealmkey>')}])
pubcs.publish('test', Item.new(HttpResponseFormat.new('PubControlSet test publish!\n')),
    false, method(:callback))
```
