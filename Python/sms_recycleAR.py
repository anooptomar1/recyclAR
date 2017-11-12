from data_access_recycle import *
#from RecyclAR import data_access_recycle
from twilio.rest import Client

from flask import Flask, request, session
from twilio.twiml.messaging_response import MessagingResponse

import boto3
import decimal

SECRET_KEY = 'a secret key'  # change this to something appropriate
app = Flask(__name__)
app.config.from_object(__name__)

#Function that creates a new user and puts it in our DynamoDB database
def create_user(Phone_Number,Name, objects=0):
	dynamodb = boto3.resource('dynamodb')
	table = dynamodb.Table('RecyclAR')
	table.put_item(
		Item={
			'Phone_Number': Phone_Number,
			'Name': Name,
			'Recycled_Object': objects,
		}
	)

#Function that retrieves user through their phone number
def retreive_user(Phone_Number):
	dynamodb = boto3.resource('dynamodb')
	table = dynamodb.Table('RecyclAR')
	try:
		response = table.get_item(
			Key={
				'Phone_Number': Phone_Number
			}
		)
		item = response['Item']
		return item
	except KeyError as e:
		return None

#Function that retrieves user's current recycled items
def retreive_recycle(Phone_Number):
	i = 0	#iterator value
	count = 0	#value for size of dynamoDB table
	temp = 0	#value to store the recycled object json
	flag = True	#bool flag used to break out of try catch while loop later
	
	#initializing the table for access
	dynamodb = boto3.resource('dynamodb')
	table = dynamodb.Table('RecyclAR')

	#member function that returns the whole table in form of a json
	response = table.scan()
	data = response['Items']
	
	#This try catch while loop basically iterates through all elements of the table
	# we iterate until an indexerror which indicates that we reached the end of the table
	while flag:
		try:
			dataprime=data[i]['Phone_Number']	#current number that iterator is on

			if dataprime == str(Phone_Number):	#if the iterator value equals the number we're searching for we set the temp to that current number's recycled object total
				temp = data[i]['Recycled_Object']

				sender_numbo = str(dataprime)

				user = retreive_user(str(dataprime))  # name lookup in database

				sender_num = user['Name']

				#new_message = ("Welcome back {}! Your current recycle count is {}.").format(sender_num, temp)

				'''
				message = client.messages.create(
    				to=sender_numbo, 
    				from_="+16175051429",
    				body=("Welcome back {}! Your current recycle count is {}.").format(sender_num, temp) ) 
				'''
			count+=1
			i+=1
		except IndexError:
			flag = False

	#print(dataprime)
	#print(temp)

	#return new_message
	return temp



#RecyclAR

# Find these values at https://twilio.com/user/account
account_sid = "AXXXXXXXX"
auth_token = "XXXXXXXXX"
client = Client(account_sid, auth_token)


#Current ngrok server running
#https://0ca3f706.ngrok.io  

@app.route("/", methods=['GET', 'POST'])
def scanner_user():

	counter = session.get('counter', 0)  # Get counter value, otherwise initialize to 0

	counter += 1  # Increment counter
	session['counter'] = counter  # Set counter to incremented value

	# For hard resetting
	#session['counter'] = 0

	# For debug
	print(counter)

	sender_num = request.values.get('From', None)  # number text recieved from
	sender_msg = request.values.get('Body', None)  # message body of text
	user = retreive_user(sender_num)  # name lookup in database

	url2 = "http://www.example.com/index.php?id=%s" % str(sender_num)
	
	#url that we send to the user so they can see their top scores
	url = "recyclar.fullcirclerun.com"	

	respo = MessagingResponse()
	if counter == 1 and user is not None:  # Returning user first text, retrieves recycle count.
		val = retreive_recycle(sender_num)
		#print(val)
		#respo.message(str(sentence))
		session['counter'] = 0
		respo.message("Welcome back {}! Your current recycle count is {}. Check out where you stand in your community's leaderboard! {}".format(user['Name'], val, url) )
		return str(respo)
	elif counter == 1 and user is None:  # New user first text
		respo.message("Welcome to RecyclAR! Please send us your name.")
		return str(respo)
	elif counter == 2 and user is None:  # New user registration (2nd text)
		# save from_number,msg_body to database
		respo.message("You have been successfully registered! Here we will keep you updated on how much you recycled with us. Thank you!")
		create_user(sender_num, sender_msg)
		session['counter'] = 0
		return str(respo)
	
	# This is the default case in which it just queries about how much the user has recycled.
	val = retreive_recycle(sender_num)
	print(val)
	#respo.message(sentence)
	respo.message("Welcome back {}! Your current recycle count is {}. Check out where you stand in your community's leaderboard! {}".format(user['Name'], val, url) )
	return str(respo)
		

# Run app in debug
if __name__ == "__main__":
	app.run(debug=True)





