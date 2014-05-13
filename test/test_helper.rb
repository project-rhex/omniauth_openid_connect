$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start
require 'minitest/autorun'
require 'rack/test'
require 'webmock'
require 'omniauth'
require 'omniauth_openid_connect'
require 'webmock/minitest'
require 'pry'
require 'webmock'


def create_client(host = "http://localhost",client_id ="my_id",secret="my_secret", args = {})
  OmniAuth::Strategies::OpenIDConnect.new(nil,host,client_id,secret, args)
end
