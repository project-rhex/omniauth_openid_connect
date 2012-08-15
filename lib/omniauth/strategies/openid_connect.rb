require 'cgi'
require 'uri'
require 'omniauth'
require 'openid_connect'
require 'timeout'
require 'openssl'
require 'open-uri'

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

      option :discover, false
      option :user_info_endpoint, "/user_info"
      option :authorization_endpoint, "/authorize"
      option :token_endpoint, '/token'
      option :check_id_endpoint, '/check_id'
      option :x509_url, nil
      option :x509_encryption_url, nil
      option :jwk_url,nil
      option :jwk_encryption_url, nil
      option :client_jwk_singing_key, nil
      option :client_jwk_encryption_key, nil
      option :client_x509_client_key, nil
      option :client_x509_encryption_key, nil
      option :client_signing_alg, :HS256
      option :issuer, nil 
      option :scope, "openid profile"
      
      
     attr_accessor :access_token


  

      def client_attributes
        options.client_options.merge({identifier:options.client_id,
         secret:options.client_secret,
         host:options.host,
         user_info_endpoint:  options.user_info_endpoint,
         authorization_endpoint: options.authorization_endpoint, 
         token_endpoint:  options.token_endpoint, 
         check_id_endpoint:  options.check_id_endpoint}
        )
      end     
    
      
      def client
        @client ||= ::OpenIDConnect::Client.new(client_attributes)
      end

      def callback_url
        full_host + script_name + callback_path
      end

      credentials do
        expires_at = (access_token.expires_in >= 0 ) ? access_token.expires_in.try(:from_now) : nil
        hash = {'token' => access_token.access_token}
       # hash.merge!('refresh_token' => access_token.refresh_token) if expires_at && access_token.refresh_token
        hash.merge!('expires_at' => expires_at) if expires_at
        hash.merge!('expires' => !expires_at.nil?)
        hash
      end

      def request_phase
        client.redirect_uri = callback_url
        uri =  client.authorization_uri(
                   response_type: :code,
                   nonce: new_nonce,
                   scope: options[:scope]
                 )    
        redirect uri
      end


      def callback_phase
        
        if request.params['error'] || request.params['error_reason']
          raise CallbackError.new(request.params['error'], request.params['error_description'] || request.params['error_reason'], request.params['error_uri'])
        end

        self.access_token = build_access_token
        super
        
        rescue  CallbackError => e
          fail!(:invalid_credentials, e)
        rescue ::SocketError => e
          fail!(:failed_to_connect, e)
        rescue 
          fail!(:error,$!)  
      end
      
      
      uid{ raw_info[:user_id]  }

        info do
          prune!(raw_info.dup)
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
          issuer: issuer,
          client_id: options.client_id,
          nonce: stored_nonce
        )
        access_token
      end
      
      def issuer
        options.issuer || "#{options.client_options[:scheme]}://#{options.host}" + ((options.client_options[:port]) ? ":#{options.client_options[:port].to_s}" : "")
      end
     
      def check_id!(id_token)
        
        raise ::OpenIDConnect::Exception.new('No ID Token was given.') if id_token.blank?
        ::OpenIDConnect::ResponseObject::IdToken.decode(
          id_token, (get_idp_signing_key() || options[:client_secret])
        )
      end
      
      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end

      
      def new_nonce
        session[:nonce] = SecureRandom.hex(16)
      end

      def stored_nonce
        session.delete(:nonce)
      end
      
      def get_idp_encryption_key
        
      end
      
      def get_idp_signing_key
        
        key = nil
        if x509_url
          cert = parse_x509_key(x509_url)
          key = cert.public_key
        elsif jwk_url
          key = parse_jwk_key(jwk_url)
        end
        key
      end
      
      
      def x509_url
        return host_endpoint+options["x509_url"]  if options["x509_url"] 
      end
      
      def jwk_url
        return host_endpoint+options["jwk_url"]  if options["jwk_url"] 
      end
      
      
      def host_endpoint
        port = options["client_options"]["port"]
        scheme = options["client_options"]["scheme"] || "https"
        
        "#{scheme}://#{options.host}#{(port)? ':'+port : ""}"
      end
      
      def parse_x509_key(url)
        OpenSSL::X509::Certificate.new open(url).read
      end
      
      def parse_jwk_key(url)
        jwk_str = open(url).read
        json = JSON.parse(jwk_str)
        # there should be only 1 key
        jwk = json["keys"][0]
        key = nil
        case jwk["alg"].downcase
          when "rsa"
             key = create_rsa_key(jwk["mod"],jwk["exp"])
          when "ec"
             key = create_ec_key(jwk["x"],jwk["y"],jwk["crv"])
          else
          
        end
        key
      end
      
      
      def create_request_object
     
        ::OpenIDConnect::RequestObject.new(
           user_info: {
             claims: {
               name: :required,
               email: :optional
             }
           }
         ).to_jwt(key_or_secret, :HS256)
      end
      
      def create_rsa_key(mod,exp)
        key = OpenSSL::PKey::RSA.new
        exponent = OpenSSL::BN.new decode(exp)
        modulus = OpenSSL::BN.new decode(mod)
        key.e = exponent
        key.n = modulus
        key
      end
      
      def key_or_secret
        case options.client_signing_alg
          when :HS256,:HS384, :HS512
            return options.client_secret
          when :RS256,:RS384,:RS512
            if options.client_jwk_signing_key
                return parse_jwk_key(options.client_jwk_signing_key)
            elsif options.client_x509_signing_key
                return parse_x509_key(options.client_x509_signing_key)
            end
          else
        end
            
      end
      
      
      def create_ec_key(x,y,crv)
        
      end
      
      
      def decode(str)
         UrlSafeBase64.decode64(str).unpack('B*').first.to_i(2).to_s
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
OmniAuth.config.add_camelization 'open_id_connect', 'OpenIDConnect'
