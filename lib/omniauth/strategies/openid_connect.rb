require 'cgi'
require 'uri'
require 'omniauth'
require 'openid_connect'
require 'timeout'

module OmniAuth
  module Strategies
    # Authentication strategy for authenticating with OpenIDConnect servers
    class OpenIDConnect
      include OmniAuth::Strategy

      args [:host, :client_id, :client_secret]
      option :name, "openid_connect"
      option :client_id, nil
      option :client_secret, nil
      option :client_options, {scheme:"https", port:80}
      option :authorize_params, {}
      option :authorize_options, [:scope]
      option :token_params, {}
      option :token_options, []
      option :discover, false
      option :user_info_endpoint, "/user_info"
      option :authorization_endpoint, "/authorize"
      option :token_endpoint, '/token'
      option :check_id_endpoint, '/check_id'
       

     attr_accessor :access_token


      def client_attributes
        options.client_options.merge({identifier:options.client_id,
         secret:options.client_secret,
         host:options.host,
         user_info_endpoint:  options.user_info_endpoint,
         authorization_endpoint: options.authorization_endpoint, 
         token_endpoint:  options.token_endpoint, 
         check_id_endpoint:  options.check_id_endpoint})
      end     
    
      
      def client
        @client ||= ::OpenIDConnect::Client.new(client_attributes)
      end

      def callback_url
        full_host + script_name + callback_path
      end

      credentials do
        expires_at = (access_token.expires_in >= 0 ) ? access_token.expires_in.try(:from_now) : nil
        hash = {'token' => access_token}
        hash.merge!('refresh_token' => access_token.refresh_token) if expires_at && access_token.refresh_token
        hash.merge!('expires_at' => expires_at) if expires_at
        hash.merge!('expires' => !expires_at.nil?)
        hash
      end

      def request_phase
        client.redirect_uri = callback_url
        uri =  client.authorization_uri(
            response_type: :code,
            nonce: new_nonce,
            scope: :openid, #scope,
            request: ::OpenIDConnect::RequestObject.new(
              id_token: {
                max_age: 10,
                claims: {
                  auth_time: nil,
                  acr: {
                    values: ['0', '1', '2']
                  }
                }
              },
              user_info: {
                claims: {
                  name: :required,
                  email: :optional
                }
              }
            ).to_jwt(client.secret, :HS256)
          )    
        redirect uri
      end


      def callback_phase
        if request.params['error'] || request.params['error_reason']
          raise CallbackError.new(request.params['error'], request.params['error_description'] || request.params['error_reason'], request.params['error_uri'])
        end

        self.access_token = build_access_token
        # binding.pry
        #      self.access_token = access_token.refresh! if access_token.expires_in <=0
     
        super
      rescue  CallbackError => e
        fail!(:invalid_credentials, e)
      rescue ::MultiJson::DecodeError => e
        fail!(:invalid_response, e)
      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
        fail!(:timeout, e)
      rescue ::SocketError => e
        fail!(:failed_to_connect, e)
      end
      
      
      uid{ raw_info['id'] || verified_email }

        info do
          prune!({
            :name       => raw_info['name'],
            :email      => verified_email,
            :first_name => raw_info['given_name'],
            :last_name  => raw_info['family_name'],
            :image      => raw_info['picture']
          })
        end

       extra do
          prune!({
            'raw_info' => raw_info
          })
        end

        def raw_info
          unless @raw_info
           @raw_info = {}
           user_info = access_token.user_info!
           user_info.all_attributes.each {|att| @raw_info[att] = user_info.send att.to_sym}
         end
          @raw_info
        end

 
      protected

      def build_access_token
        code = request.params['code']      
        client.redirect_uri = callback_url
        client.authorization_code = code
        access_token = client.access_token!
        id_token = check_id! access_token.id_token
        id_token.verify!(
          issuer: "#{options.client_options[:scheme]}://#{options.host}",
          client_id: options.client_id,
          nonce: stored_nonce
        )
        access_token
      end
     
      def check_id!(id_token)
        raise ::OpenIDConnect::Exception.new('No ID Token was given.') if id_token.blank?
        ::OpenIDConnect::ResponseObject::IdToken.decode(
          id_token, client
        )
      end
      
      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end

      def verified_email
        raw_info['verified_email'] ? raw_info['email'] : nil
      end
      
      def new_nonce
        session[:nonce] = SecureRandom.hex(16)
      end

      def stored_nonce
        session.delete(:nonce)
      end
      
      
      # An error that is indicated in the OAuth 2.0 callback.
      # This could be a `redirect_uri_mismatch` or other
      class CallbackError < StandardError
        attr_accessor :error, :error_reason, :error_uri

        def initialize(error, error_reason=nil, error_uri=nil)
          self.error = error
          self.error_reason = error_reason
          self.error_uri = error_uri
        end
      end
    end
  end
end
OmniAuth.config.add_camelization 'openid_connect', 'OpenIDConnect'
