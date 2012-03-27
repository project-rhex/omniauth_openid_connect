# OmniAuth OpenIDConnect

This gem contains a generic OpenIDConnect strategy for OmniAuth. It can be used 
as is or as a starting point for a more advanced OpenIDConnect implementation. 

Currently this strategy expects the client registration to take place out of band,
that is it does not support the discovery services of OpenID Connect. 

## Creating an OAuth2 Strategy

To use this module simply configure it as you would any other omniauth provider.

provider :openid_connect, <host>, <client_id>, <client_secret>, {<additional_parms>}
  

To use multiple providers simply set the name of the provider in the additional
params section.


provider :openid_connect, "somecool.host.com", "my_cool_id", "my_cool_secret", {:name=>:cool_host}
provider :openid_connect, "id.host.com", "my_id_id", "my_id_secret", {:name=>:idp_host}

This will setup a provider for each of the hosts mapped to different urls.
/auth/cool_host 
/auth/idp_host



That's pretty much it!
