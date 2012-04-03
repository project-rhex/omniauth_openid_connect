# -*- encoding: utf-8 -*-
require File.expand_path('../lib/omniauth/openid-connect/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_dependency 'omniauth', '~> 1.0'
  gem.add_dependency 'rack-oauth2'
  gem.add_dependency 'openid_connect', '0.2.0.alpha3'

  gem.add_development_dependency 'rack-test'
  gem.add_development_dependency 'webmock'
  gem.add_development_dependency 'simplecov'
  

  gem.authors       = ["Rob Dingwell"]
  gem.email         = ["rob.dingwell@gmail.com"]
  gem.description   = %q{An openid connect strategy for OmniAuth.}
  gem.summary       = %q{An OpenID Conenct strategy for OmniAuth.}
  gem.homepage      = "https://github.com/rdingwell/omniauth-openid-connect"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "omniauth-openid-connect"
  gem.require_paths = ["lib"]
  gem.version       = OmniAuth::OpenIDConnect::VERSION
end
