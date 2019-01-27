Gem::Specification.new do |s|
  s.name        = 'pubcontrol'
  s.version     = '1.2.3'
  s.date        = '2019-01-27'
  s.summary     = 'Ruby EPCP library'
  s.description = 'A Ruby convenience library for publishing messages using the EPCP protocol'
  s.authors     = ['Konstantin Bokarius']
  s.email       = 'bokarius@comcast.net'
  s.files       = ['lib/pubcontrol.rb', 'lib/format.rb',
    'lib/item.rb', 'lib/pcccbhandler.rb', 'lib/pubcontrolclient.rb']
  s.homepage    = 'https://github.com/fanout/ruby-pubcontrol'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 1.9.0'
  s.add_runtime_dependency 'algorithms', '~> 0.6'
  s.add_runtime_dependency 'jwt', '~> 1.2'
  s.add_runtime_dependency 'net-http-persistent', '~> 2.9'
end
