Gem::Specification.new do |s|
  s.name        = 'pubcontrol'
  s.version     = '1.0.1'
  s.date        = '2015-01-11'
  s.summary     = 'Ruby EPCP library'
  s.description = 'A Ruby convenience library for publishing messages using the EPCP protocol'
  s.authors     = ['Konstantin Bokarius']
  s.email       = 'bokarius@comcast.net'
  s.files       = ['lib/pubcontrol.rb', 'lib/format.rb',
    'lib/item.rb', 'lib/pcccbhandler.rb', 'lib/pubcontrolclient.rb']
  s.homepage    = 'https://github.com/fanout/ruby-pubcontrol'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 1.9.0'
  s.add_runtime_dependency 'algorithms', '= 0.6.1'
  s.add_runtime_dependency 'jwt', '= 1.2.0'
end
