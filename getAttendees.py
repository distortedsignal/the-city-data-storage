import ast
import urllib.parse, urllib.request
import time
import hmac
import hashlib
import base64
import json

# Set up Auth for The City
# Get secret key and user token from file
conf = open('auth.conf', 'r', encoding='utf-8')
confStruct = ast.literal_eval(conf.read())

now = int(time.time())
verb = "GET"

url = 'https://api.onthecity.org/users'

string_to_sign = str(now) + verb + url

unencoded_hmac = urllib.parse.quote(hmac.new(confStruct['secret-key'].encode('utf-8'),
	string_to_sign.encode('utf-8'), hashlib.sha256).digest())

encoded_hmac = base64.b64encode(unencoded_hmac.encode('utf-8')).strip()

headers = {
	"X-City-Sig": str(encoded_hmac),
	"X-City-User-Token": confStruct["user-token"],
	"Accept": 'application/vnd.thecity.admin.v1+json',
	"X-City-Time": now
}

print(json.dumps(headers).encode('utf-8'))

a = urllib.request.urlopen(url, json.dumps(headers).encode('utf-8')).read()




# Initialize database connection

# Loop through users and persist them to the database