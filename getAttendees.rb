require 'openssl'
require 'CGI'
require 'json'
require 'base64'
require 'net/http'
require 'net/https'
require 'time'
require 'csv'

def safe_get_item(item)
	if item == nil then
		return ""
	end

	return item
end

def get_user_array(user, user_attributes)
	user_arr = []
	user_attributes.each do |attribute|
		user_arr.push(safe_get_item(user[attribute]))
	end
	return user_arr
end

def get_user_url(page)
	url_base = "https://api.onthecity.org"
	url_path = "/users"
	url_params = "?page=" + page.to_s

	return "#{url_base}#{url_path}#{url_params}"
end

def get_string_to_sign(unix_time, http_verb, full_url)
	return unix_time.to_s + http_verb + full_url
end

def sign_string(secret_key, string_to_sign)
	uncoded_hmac = OpenSSL::HMAC.digest('sha256', secret_key, string_to_sign)
	unescaped_hmac = Base64.encode64(uncoded_hmac).chomp
	return CGI.escape(unescaped_hmac)
end

def get_user_page(page)
	# This code ripped from https://github.com/thecity/thecity-admin-ruby/blob/0b0d0c019143b7c04bfb583c3e69567321017027/examples/thecity_headers.rb
	full_url = get_user_url(page)

	unix_time = Time.now.to_i
	string_to_sign = get_string_to_sign(unix_time, "GET", full_url)

	# Get secret key
	file = File.read('auth.conf')
	auth_dict = JSON.parse(file)

	hmac_signature = sign_string(auth_dict['secret-key'], string_to_sign)

	headers = {}
	headers['X-City-Sig'] = hmac_signature
	headers['X-City-User-Token'] = auth_dict['user-token']
	headers['Accept'] = 'application/vnd.thecity.admin.v1+json' # This is required by the API
	headers['X-City-Time'] = unix_time.to_s # Apparently Ruby doesn't like serializing ints to JSON

	uri = URI(full_url)
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE #TODO This.
	request = Net::HTTP::Get.new(uri, initheaders = headers)
	return http.request(request)
end

# Get the first page of user results
response = get_user_page(1)
# Get the page into a format we can work with
response_body = JSON.parse(response.body())
# Find out how many pages there are
pages = response_body['total_pages']
# Set attributes that we expect from users
user_attributes = ["admin_url", "api_url", "internal_url", "updated_at", "last_logged_in", "secondary_phone", 
	"last_engaged", "title", "id", "first", "primary_campus_name", "last", "head_of_household", "nickname", "active", 
	"primary_phone_type", "primary_phone", "member_since", "birthdate", "email_bouncing", "secondary_phone_type", 
	"primary_campus_id", "contact_updated_at", "type", "staff", "created_at", "gender", "external_id_1", 
	"external_id_2", "external_id_3", "external_chms_id", "middle", "email"]

# Open the CSV and...
CSV.open('users.csv', 'wb') do |csv|
	# Write the user attributes as a header to the CSV
	csv << user_attributes
	# For each page in the database...
	(1..pages).each do |page_num|
		# Get a page by page number
		page = get_user_page(page_num)
		# Get the page body in a way that we can use it
		page_body = JSON.parse(page.body())
		# Get the user list
		page_body['users'].each do |user|
			csv << get_user_array(user, user_attributes)
		end
	end
end






