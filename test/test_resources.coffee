gocardless = require '../lib'
fixtures = require './fixtures'
gently = new (require 'gently')
should = require 'should'

Client = gocardless.Client
{Resource, Subscription, Bill, PreAuthorization} = gocardless.resources

mock_account_details = fixtures.mock_account_details
createMockAttrs = fixtures.createMockAttrs

class TestResource extends Resource
  endpoint: "/testendpoint/:id"

  constructor: (attrs, client) ->
    attrs = createMockAttrs(attrs)
    super


describe 'Resource', ->
  it 'endpoint declared by class', ->
    resource = new TestResource({"id":"1"}, null)
    resource.getEndpoint().should.equal "/testendpoint/1"

  it 'resource attributes', ->
    attrs = {"key1":"one", "key2":"two", "key3":"three", "id":"1"}
    res = new TestResource(JSON.parse(JSON.stringify(attrs)), null)
    for own key, value of attrs
      res[key].should.equal value

  it 'resource created at is date', ->
    dateText = '2012-04-18T17:53:12Z'
    created = new Date dateText
    attrs = createMockAttrs({"created_at":dateText, "id":"1"})
    res = new TestResource(attrs, null)
    res.created_at.should.eql created

  it 'resources with equal attrs are equal', ->
    attrs = createMockAttrs({ "someattr":"someval" })
    res1 = new TestResource(attrs, null)
    res2 = new TestResource(attrs, null)
    res1.should.eql res2

  describe 'FindResource', ->

    it 'find resource by id with client', ->
      client = new Client mock_account_details
      gently.expect gocardless.Client.prototype, 'apiGet', (path, cb) ->
        cb null, {id: "1"}
      TestResource.findWithClient "1", client, (err, resource) ->
        should.not.exist err
        resource.id.should.equal "1"

  class TestDateResource extends Resource
    endpoint: "/dates"
    date_fields: ["modified", "activated"]

  describe 'DateResourceField', ->

    it 'date fields are converted', ->
      DATE1 = "2020-10-10T01:01:00"
      DATE2 = "2020-10-10T01:01:03"
      mod_date = new Date DATE1
      act_date = new Date DATE2
      params = {
        "modified":mod_date.toISOString()
        "activated":act_date.toISOString()
      }
      res = new TestDateResource(createMockAttrs(params), null)
      res.modified.should.eql mod_date
      res.activated.should.eql act_date

  class TestReferenceResource extends Resource
    endpoint: "/referencing"
    reference_fields: ["test_resource_id"]

  describe 'ReferenceResource', ->

    it 'date fields inherited', ->
      params = createMockAttrs({"test_resource_id":"123"})
      res = new TestReferenceResource(params, null)
      res.created_at.should.be.instanceOf Date

    it 'date with null attr does not throw', ->
      params = createMockAttrs({"modified_at":null})
      class TestModeResource extends Resource
        date_fields: _super::date_fields.concat ["modified_at"]
      res = new TestModeResource params

  describe 'SubscriptionCancel', ->

    it 'cancel puts', (done) ->
      client = new Client mock_account_details
      gently.expect gocardless.Client.prototype, 'apiPut', (path, data, cb) ->
        path.should.equal "/subscriptions/#{fixtures.subscription_json.id}/cancel"
        cb(null)
      sub = new Subscription(fixtures.subscription_json, client)
      sub.cancel (err, res) ->
        done()

  describe 'PreAuthCancel', ->

    it 'cancel puts', (done) ->
      client = new Client mock_account_details
      gently.expect gocardless.Client.prototype, 'apiPut', (path, data, cb) ->
        path.should.equal "/pre_authorizations/#{fixtures.preauth_json.id}/cancel"
        cb(null)
      preauth = new PreAuthorization(fixtures.preauth_json, client)
      preauth.cancel (err, res) ->
        done()

  describe 'PreAuthBillCreation', ->

    it 'create bill calls client api post', (done) ->
      client = new Client mock_account_details
      gently.expect gocardless.Client.prototype, 'apiPost', (path, data, cb) ->
        path.should.equal "/bills"
        expected_params = {
            "bill":{
              "amount":10,
              "pre_authorization_id":"1234",
              "name":"aname",
              "description":"adesc"
              }
            }
        data.should.eql expected_params
        cb null, fixtures.bill_json
      Bill.createUnderPreauth 10, "1234", client, {name:"aname", description:"adesc"}, (err, result) ->
        should.not.exist err
        result.should.be.instanceOf Bill
        done()

    it 'preauth create calls bill create', ->
      gently.expect gocardless.resources.Bill, 'createUnderPreauth', (amount, pre_auth_id, client, {name, description}, callback) ->
        amount.should.equal 10
        pre_auth_id.should.equal pre_auth.id
        should.not.exist client
        name.should.equal "aname"
        description.should.equal "adesc"
      pre_auth = new PreAuthorization(fixtures.preauth_json, null)
      pre_auth.createBill(10, name="aname", description="adesc")

  describe 'BillRetry', ->

    it 'retry post', ->
      client = new Client mock_account_details
      gently.expect gocardless.Client.prototype, 'apiPost', (path, data, cb) ->
        path.should.equal "/bills/#{fixtures.bill_json["id"]}/retry"
      bill = new Bill(fixtures.bill_json, client)
      bill.retry()
