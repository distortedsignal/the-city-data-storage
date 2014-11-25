# This code ripped from https://api.onthecity.org/docs/admin
require 'openssl'
require 'CGI'
require 'json'
require 'base64'

unix_time = Time.now.to_i
http_verb = "GET"
string_to_sign = "#{unix_time}#{http_verb}https://api.onthecity.org/users"

# Get secret key
file = File.read('auth.conf')
auth_dict = JSON.parse(file)

secret_key = auth_dict['secret-key']
uncoded_hmac = OpenSSL::HMAC.digest('sha256', secret_key, string_to_sign)
unescaped_hmac = Base64.encode64(uncoded_hmac).chomp()
hmac_signature = CGI.escape(unescaped_hmac)

