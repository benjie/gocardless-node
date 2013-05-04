nodeUrl = require 'url'
gocardless = require '../lib'
should = require 'should'
querystring = require 'querystring'
gently = new (require 'gently')
fixtures = require './fixtures'

utils = gocardless.utils
Client = gocardless.Client
{ClientError, SignatureError, ValueError} = gocardless.exceptions

mock_account_details = fixtures.mock_account_details
createMockAttrs = fixtures.createMockAttrs

process.env.GOCARDLESS_ENVIRONMENT = 'sandbox'

createMockClient = (details) ->
  return new Client(details)

getUrlParams = (url) ->
  parsed = nodeUrl.parse url, true
  return parsed.query

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

  it 'get pre authorization', (done) ->
    mock_date = new Date().toISOString()
    mock_attrs = {
        "user_id":"123456",
        "expires_at":mock_date,
        "next_interval_start":mock_date
        }
    _getResourceTester("preAuthorization", createMockAttrs(mock_attrs), done)

  it 'get bill', (done) ->
    _getResourceTester("bill", createMockAttrs({
      "paid_at":new Date().toISOString()
      "user_id":"someuserid"
    }), done)

  it 'set details valueerror raised when details not present', ->
    details = JSON.parse(JSON.stringify(mock_account_details))
    details["access_token"] = details["token"]
    delete details["token"]
    for key in Object.keys details
      #make sure that every key is required by passing in a hash WiTh ->
      #all but one key missing
      invalid_details = JSON.parse(JSON.stringify(details))
      delete invalid_details[key]
      (->
        client = new Client invalid_details
      ).should.throw()

  it 'create bill', (done) ->
    client = new Client mock_account_details
    gently.expect gocardless.Client.prototype, 'apiPost', (path, data, cb) ->
      path.should.equal "/bills"
      data.bill.should.eql {
        "amount":10,
        "pre_authorization_id": "someid"
      }
      cb null, fixtures.bill_json
    mock_bill = new gocardless.resources.Bill JSON.parse(JSON.stringify(fixtures.bill_json)), client
    client.createBill 10, "someid", (err, bill) ->
      should.not.exist err
      bill.should.eql mock_bill

      done()

describe 'ConfirmResource', ->
  client = null
  resource_path = null
  params = null
  before ->
    client = createMockClient(mock_account_details)
    resource_path = "/somepath/morepath"
  beforeEach ->
    params = {
      "resource_uri":"http://aresource.com/api/v1#{resource_path}"
      "resource_id":"1",
      "resource_type":"subscription",
    }

  it 'incorrect signature raises', ->
    params["signature"] = "asignature"
    (->
      client.confirmResource(params)
    ).should.throw(SignatureError)

  it 'resource posts', (done) ->
    params["signature"] = utils.generateSignature(params, mock_account_details["app_secret"])
    gently.expect gocardless.Client.prototype, 'apiPost', (path, data, cb) ->
      path.should.equal "/confirm"
      data.should.eql {
        "resource_type":params["resource_type"],
        "resource_id":params["resource_id"]
      }
      # XXX: CHECK THE AUTHENTICATION
      #expected_auth = [mock_account_details["app_id"], mock_account_details["app_secret"]]
      cb(null)
    client.confirmResource params, ->
      done()

describe 'UrlBuilder', ->
  app_secret = "12345"
  merchant_id = "123"
  app_id = "234234"
  mock_client = {
    merchant_id: merchant_id
    app_secret: app_secret
    app_id: app_id
    base_url: "https://gocardless.com"
  }
  urlbuilder = new gocardless.urlbuilder.UrlBuilder(mock_client)

  makeMockParams = (paramdict) ->
    mock_params = {
      toDict: -> paramdict
    }
    unless paramdict["resource_name"]?
      mock_params.resource_name = "aresource"
    else
      mock_params.resource_name = paramdict["resource_name"]
      delete paramdict["resource_name"]

    return mock_params

  it 'urlbuilder url contains correct parameters', ->
    params = makeMockParams({"resource_name": "bill", "amount":20.0, "merchant_id":"merchid"})
    url = urlbuilder.buildAndSign(params)
    urlparams = getUrlParams(url)
    for k,v of params.toDict()
      if k is "resource_name"
        continue
      urlparams["bill[#{k}]"].should.equal ""+v

  it 'resource name is singularized in url', ->
    params = makeMockParams({"resource_name":"bills", "amount":20.0})
    url = urlbuilder.buildAndSign(params)
    urlparams = getUrlParams(url)
    urlparams["bill[amount]"].should.exist

  it 'add merchant id to limit', ->
    params = makeMockParams({"resource_name": "bill", "merchant_id":merchant_id})
    url = urlbuilder.buildAndSign(params)
    urlparams = getUrlParams(url)
    urlparams["bill[merchant_id]"].should.equal merchant_id

  it 'url contains state', ->
    params = makeMockParams({})
    url = urlbuilder.buildAndSign(params, {state:"somestate"})
    urlparams = getUrlParams(url)
    urlparams["state"].should.equal "somestate"

  it 'url contains redirect', ->
    params = makeMockParams({})
    url = urlbuilder.buildAndSign(params, {redirect_uri:"http://somesuchplace.com"})
    urlparams = getUrlParams(url)
    urlparams["redirect_uri"].should.equal "http://somesuchplace.com"

  it 'url contains cancel', ->
    params = makeMockParams({})
    url = urlbuilder.buildAndSign(params, {cancel_uri:"http://cancel"})
    urlparams = getUrlParams(url)
    urlparams["cancel_uri"].should.equal "http://cancel"

  it 'url contains nonce', ->
    params = makeMockParams({"somekey":"someval"})
    url = urlbuilder.buildAndSign(params)
    urlparams = getUrlParams(url)
    should.exist urlparams["nonce"]

  it 'url nonce is random', ->
    params = makeMockParams({"somekey":"somval"})
    url1 = urlbuilder.buildAndSign(params)
    url2 = urlbuilder.buildAndSign(params)
    getUrlParams(url1)["nonce"].should.not.equal getUrlParams(url2)["nonce"]

  it 'url contains client id', ->
    params = makeMockParams({"somekey":"someval"})
    url = urlbuilder.buildAndSign(params)
    urlparams = getUrlParams(url)
    urlparams["client_id"].should.equal app_id

  it 'url contains resource name', ->
    params = makeMockParams({"resource_name" : "pre_authorizations"})
    url = urlbuilder.buildAndSign(params)
    path = nodeUrl.parse(url, true).pathname
    path.should.equal "/connect/pre_authorizations/new"

  it 'url contains timestamp', ->
    params = makeMockParams({"somekey":"somval"})
    url = urlbuilder.buildAndSign(params)
    urlparams = getUrlParams(url)
    Math.abs(new Date(urlparams.timestamp).getTime() - new Date().getTime()).should.be.lessThan 1000
    urlparams.timestamp.length.should.be.greaterThan 10

  it 'other timezones use u t c'

describe 'MerchantUrl', ->
  client = createMockClient(mock_account_details)
  mock_auth_code = ("DlydRBP+1iHjxPUBtNTtO5jCldrkbnrdhpaaVqiU1F4mkhwiMJQCNlAJ6fPSN65NY")
  access_token_response = {
    "access_token":"thetoken",
    "token_type":"bearer",
    "scope":"manage_merchant:themanagedone"
  }

  it 'merchant url parameters', ->
    url = client.newMerchantUrl("http://someurl")
    params = getUrlParams(url)
    expected = {
      "client_id":mock_account_details["app_id"],
      "redirect_uri":"http://someurl",
      "scope":"manage_merchant",
      "response_type":"code"
    }
    expected.should.eql params

  it 'merchant url with merchant prepop', -> ->
    merchant = {
        "name":"merchname",
        "billing_address_1":"myadd1",
        "billing_address_2":"myadd2",
        "billing_town":"smalltown",
        "billing_county":"godknows",
        "billing_postcode":"PSTCDE",
        "user":{
          "first_name":"nameone",
          "last_name":"nametwo",
          "email":"emailemail.com"
          }
        }
    url = client.newMerchantUrl("http://someutl/somepath", {merchant:merchant})
    params = getUrlParams(url)
    params["merchant[name]"].should.equal "merchname"
    params["merchant[user][first_name]"].should.equal "nameone"

  it 'merchant url state', ->
    url = client.newMerchantUrl("http://someurl", {state:"thestate"})
    params = getUrlParams(url)
    params["state"].should.equal "thestate"

  it 'fetch client access token basic authorization', (done) ->
    expected_data = {
      "client_id":mock_account_details["app_id"],
      "code":mock_auth_code,
      "redirect_uri":"http://someurl",
      "grant_type":"authorization_code"
    }
    query = utils.toQuery(expected_data)
    expected_auth = [ mock_account_details["app_id"], mock_account_details["app_secret"]]
    gently.expect gocardless.Client.prototype, '_request', (method, path, data, cb, auth) ->
      method.should.equal 'post'
      path.should.equal "/oauth/access_token?#{query}"
      auth.should.eql expected_auth
      cb null, access_token_response
    next = (err, res) ->
      done()
    client.fetchAccessToken expected_data["redirect_uri"], mock_auth_code, next

  it 'fetch client sets access token and merchant id', ->
    gently.expect gocardless.Client.prototype, '_request', (method, path, data, cb, auth) ->
      cb null, access_token_response
    client.fetchAccessToken "http://someuri", "someauthcode", (err, result) ->
      result.should.equal "thetoken"
      client.access_token.should.equal "thetoken"
      client.merchant_id.should.equal "themanagedone"

class Matcher
  ###Object for comparing objects WiTh an arbitrary comparison function ->

  This is used as a matcher for testing properties of arguments in mocks
  see http://www.voidspace.org.uk/python/mock/examples.html#matching-any-argument-in-assertions
  ###
  constructor: (func) ->
    func = func
  __eq__: (other) ->
    return func(other)

describe 'ClientUrlBuilder', ->
  ###Integration test for the Client <-> UrlBuilder relationship

  Tests that the url building methods on the client correctly
  call methods on the urlbuilder class
  ###

  urlbuilderArgumentCheck = (method, expected_type, args...) ->
    gently.expect gocardless.urlbuilder.UrlBuilder.prototype, 'buildAndSign', (params, {state, redirect_uri, cancel_uri}={}) ->
      params.should.be.instanceOf expected_type
      should.not.exist cancel_uri
      should.not.exist redirect_uri
      should.not.exist state
      return "http://someurl"
    c = createMockClient(mock_account_details)
    c[method].apply c, args
    gently.verify()

  paramsArgumentCheck = (method, params_class, args..., kwargs) ->
    arg1 = args[0]
    rest = args.slice(1)
    klass = params_class
    expected = gently.expect (a1, merchant, mArgs..., mDict) ->
      a1.should.equal arg1
      merchant.should.equal mock_account_details["merchant_id"]
      mArgs.should.eql rest
      mDict.should.eql kwargs
    mock_class = class extends params_class
      constructor: ->
        expected.apply @, arguments
        super
    gocardless.urlbuilder[params_class.name] = mock_class
    c = createMockClient(mock_account_details)
    c[method].apply c, args.concat kwargs
    gently.verify()
    mock_class = gocardless.urlbuilder[params_class.name]

  it 'new preauth calls urlbuilder', ->
    urlbuilderArgumentCheck("newPreauthorizationUrl", gocardless.urlbuilder.PreAuthorizationParams, 3, 7, "day")

  it 'new pre auth calls urlbuilder', ->
    urlbuilderArgumentCheck("newPreAuthorizationUrl", gocardless.urlbuilder.PreAuthorizationParams, 3, 7, "day")

  it 'new preauth params constructor', ->
    paramsArgumentCheck("newPreauthorizationUrl", gocardless.urlbuilder.PreAuthorizationParams, 3, 7, "day", {expires_at:new Date(+new Date()+1000000), name:"aname", description:"desc", interval_count:5, calendar_intervals:false, user:{"somekey":"somval"}, setup_fee:null})

  it 'new bill calls urlbuilder', ->
    urlbuilderArgumentCheck("newBillUrl", gocardless.urlbuilder.BillParams, 4)

  it 'new bill params constructor', ->
    paramsArgumentCheck("newBillUrl", gocardless.urlbuilder.BillParams, 10, {name:"aname", user:{"key":"val"}, description:"adesc"})

  it 'new subscription calls urlbuilder', ->
    urlbuilderArgumentCheck("newSubscriptionUrl", gocardless.urlbuilder.SubscriptionParams, 10, 10, "day")

  it 'new sub params constructor', ->
    paramsArgumentCheck("newSubscriptionUrl", gocardless.urlbuilder.SubscriptionParams, 10, 23, "day", {name:"name", description:"adesc", start_at:new Date(), expires_at:new Date(new Date().getTime() + (100*1000)), interval_count:20, user:{"key":"val"}, setup_fee:20})
