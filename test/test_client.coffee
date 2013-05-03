gocardless = require '../lib'
should = require 'should'
querystring = require 'querystring'
gently = new (require 'gently')
fixtures = require './fixtures'

Client = gocardless.Client
ClientError = gocardless.exceptions.ClientError

mock_account_details = {
  'app_id': 'id02'
  'app_secret': 'sec01'
  'access_token': 'tok01'
  'merchant_id': fixtures.merchant_json["id"]
  'environment': 'sandbox'
}

createMockClient = (details) ->
  return new Client(details)

getUrlParams = (url) ->
  return querystring.parse url

describe 'Client', ->
  account_details = null
  client = null
  before ->
    account_details = JSON.parse JSON.stringify mock_account_details
    client = createMockClient(account_details)

  it 'error raises clienterror', ->
    gently.expect gocardless.Request.prototype, 'perform', (cb) ->
      cb null, {error:"anerrormessage"}
    client.apiGet "/somepath", (err, res) ->
      should.not.exist res
      should.exist err
      err.should.be.instanceOf ClientError

