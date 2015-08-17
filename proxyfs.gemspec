require './lib/proxyfs/version'

Gem::Specification.new do |s|
  s.name        = 'proxyfs'
  s.version     = ProxyFS::VERSION
  s.date        = Time.now.strftime '%Y-%m-%d'
  s.summary     = "Proxy file system"
  s.description = "Proxy file system"
  s.authors     = ["A. Levenkov"]
  s.email       = 'artem@levenkov.org'
  s.files       = Dir["lib/**/*.rb"]
  s.homepage    =
    'http://github.com/telum/ruby-proxyfs/'
  s.license       = 'MIT'
end
