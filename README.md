ruby-pubcontrol
===============

Author: Konstantin Bokarius <kon@fanout.io>

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

pub = PubControl.new({'uri' => 'https://api.fanout.io/realm/<myrealm>',
    'iss' => '<myrealm>', 'key' => Base64.decode64('<realmkey>')})
pub.publish('test', Item.new(HttpResponseFormat.new('Test publish!')))
pub.publish_async('test', Item.new(HttpResponseFormat.new(
    'Test async publish!')), method(:callback))
pub.finish
```
