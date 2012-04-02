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

## License

Copyright 2012 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
