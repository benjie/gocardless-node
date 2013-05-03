gocardless = require '../lib'
should = require 'should'
querystring = require 'querystring'
gently = new (require 'gently')
fixtures = require './fixtures'

utils = gocardless.utils
Client = gocardless.Client
ClientError = gocardless.exceptions.ClientError

mock_account_details = {
  'app_id': 'id02'
  'app_secret': 'sec01'
  'access_token': 'tok01'
  'merchant_id': fixtures.merchant_json["id"]
}
process.env.GOCARDLESS_ENVIRONMENT = 'sandbox'

createMockClient = (details) ->
  return new Client(details)

getUrlParams = (url) ->
  return querystring.parse url

describe 'Client', ->
  account_details = null
  client = null
  old_env = null
  base_url = null

  before ->
    account_details = JSON.parse JSON.stringify mock_account_details
    client = createMockClient(account_details)

  beforeEach ->
    old_env = process.env.GOCARDLESS_ENVIRONMENT
    base_url = Client.base_url

  afterEach ->
    process.env.GOCARDLESS_ENVIRONMENT = old_env
    Client.base_url = base_url

  it 'error raises clienterror', ->
    gently.expect gocardless.Request.prototype, 'perform', (cb) ->
      cb null, {error:"anerrormessage"}
    client.apiGet "/somepath", (err, res) ->
      should.not.exist res
      should.exist err
      err.should.be.instanceOf ClientError
      err.message.should.equal "Error calling API, message was: anerrormessage"

  it 'error when result is list', ->
    #Test for an issue where the code which checked if
    #the response was an error failed because it did
    #not first check if the response was a dictionary.
    gently.expect gocardless.Request.prototype, 'perform', (cb) ->
      cb null, ["one", "two"]
    client.apiGet "/somepath", (err, res) ->
      should.not.exist err
      should.exist res
      res.should.eql ["one", "two"]

  it 'base url returns the correct url for production', ->
    process.env.GOCARDLESS_ENVIRONMENT = 'production'
    myclient = createMockClient(account_details)
    myclient.base_url.should.equal 'https://gocardless.com'

  it 'base url returns the correct url for sandbox', ->
    process.env.GOCARDLESS_ENVIRONMENT = 'sandbox'
    myclient = createMockClient(account_details)
    myclient.base_url.should.equal 'https://sandbox.gocardless.com'

  it 'base url returns the correct url when set manually', ->
    Client.base_url = 'https://abc.gocardless.com'
    myclient = createMockClient(account_details)
    myclient.base_url.should.equal 'https://abc.gocardless.com'

  it 'get merchant' , ->
    gently.expect gocardless.Request.prototype, 'perform', (cb) ->
      cb null, fixtures.merchant_json

    client.merchant (err, merchant) ->
      should.not.exist err
      should.exist merchant
      merchant.id.should.equal account_details.merchant_id

  _getResourceTester = (resource_name, resource_fixture, done) ->
    klassName = utils.camelize(resource_name)
    expectedKlass = gocardless.resources[klassName]
    gently.expect gocardless.Client.prototype, 'apiGet', (path, cb) ->
      cb null, resource_fixture
    client[resource_name] "1", (err, obj) ->
      should.not.exist err
      resource_fixture.id.should.equal obj.id
      obj.should.be.instanceOf expectedKlass
      done()

  it 'get subscription', (done) ->
    _getResourceTester("subscription", fixtures.subscription_json, done)

  it 'get user', (done) ->
    _getResourceTester("user", fixtures.createMockAttrs({}), done)
