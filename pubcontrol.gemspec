Gem::Specification.new do |s|
  s.name        = 'pubcontrol'
  s.version     = '0.1.1'
  s.date        = '2015-01-05'
  s.summary     = 'Ruby EPCP library'
  s.description = 'A Ruby convenience library for publishing messages using the EPCP protocol'
  s.authors     = ['Konstantin Bokarius']
  s.email       = 'bokarius@comcast.net'
  s.files       = ['lib/pubcontrol.rb', 'lib/format.rb',
    'lib/item.rb', 'lib/pccbhandler.rb', 'lib/pubcontrolset.rb']
  s.homepage    = 'http://rubygems.org/gems/pubcontrol'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 1.9.0'
  s.add_runtime_dependency 'algorithms', '= 0.6.1'
  s.add_runtime_dependency 'jwt', '= 1.2.0'
end
