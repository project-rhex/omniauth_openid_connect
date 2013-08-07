require 'test_helper'
class OpenIDConnectX509SigningTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include OmniAuth::Test::StrategyTestCase
  include WebMock::API
  
  def strategy
    # return the parameters to a Rack::Builder map call:
    [OmniAuth::Strategies::OpenIDConnect,"localhost","my_id","my_s",{x509_url: "/x509", client_options:{scheme:"https", port:nil}}]
  end

  def setup
    # @strat = create_client("http://localhost", "my_id","my_secret" )
  end
  

  
  def test_callback
    
    get '/auth/openid_connect'
    @nonce = session[:nonce]

     stub_request(:post,'https://localhost/token').to_return( :body=><<-eos
      {
       "access_token": "SlAV32hkKG",
       "token_type": "Bearer",
       "refresh_token": "8xLOxBtZp8",
       "expires_in": 3600,
       "id_token": "#{create_id_token(@nonce)}"
      }
      eos

      )
      
      
     stub_request(:get,'https://localhost/user_info').to_return( :body=><<-eos
     {
      "user_id": "248289761001",
      "name": "Jane Doe",
      "given_name": "Jane",
      "family_name": "Doe",
      "email": "janedoe@example.com",
      "picture": "http://example.com/janedoe/me.jpg"
     }
      eos

      )
      
    stub_request(:get,'https://localhost/x509').to_return( :body=>File.read("./test/fixtures/keys/x509_cert.pem"))

    get '/auth/openid_connect/callback', {code:"Qcb0Orv1zh30vL1MPRsbm-diHiMwcLyZvn1arpZv-Jxf_11jnpEX3Tgfvk", state:"af0ifjsldkj"}
    
    
  end
  



  
  
  def create_id_token(nonce)
   token =  OpenIDConnect::ResponseObject::IdToken.new ({ iss: "https://localhost",
     user_id:  "248289761001",
     aud:  "my_id",
     sub: "user_id",
     nonce:  "#{nonce}",
     exp:  9911281970,
     iat: 1311280970
    })
   key = OpenSSL::PKey::RSA.new File.read("./test/fixtures/keys/x509.pem")
   token.to_jwt(key)
  end
  
  
end
