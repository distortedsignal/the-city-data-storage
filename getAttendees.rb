require 'openssl'
require 'CGI'
require 'json'
require 'base64'
require 'net/http'
require 'net/https'
require 'time'

# This code ripped from https://github.com/thecity/thecity-admin-ruby/blob/0b0d0c019143b7c04bfb583c3e69567321017027/examples/thecity_headers.rb
unix_time = Time.now.to_i
http_verb = "GET"
string_to_sign = "#{unix_time}#{http_verb}https://api.onthecity.org/users"

# Get secret key
file = File.read('auth.conf')
auth_dict = JSON.parse(file)

secret_key = auth_dict['secret-key']
uncoded_hmac = OpenSSL::HMAC.digest('sha256', secret_key, string_to_sign)
unescaped_hmac = Base64.encode64(uncoded_hmac).chomp
hmac_signature = CGI.escape(unescaped_hmac)

headers = {}
headers['X-City-Sig'] = hmac_signature
headers['X-City-User-Token'] = auth_dict['user-token']
headers['Accept'] = 'application/vnd.thecity.admin.v1+json'
headers['X-City-Time'] = unix_time.to_s
headers['Content-Type'] = 'application/json'

uri = URI('https://api.onthecity.org/users')
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE #TODO This.
request = Net::HTTP::Get.new(uri, initheaders = headers)
response = http.request(request)

puts response

