gocardless = require '../lib'
fixtures = require './fixtures'

{Resource, Subscription, Bill, PreAuthorization} = gocardless.resources

class TestResource extends Resource
  endpoint: "/testendpoint/:id"

  constructor: (attrs, client) ->
    attrs = createMockAttrs(attrs)
    super

class TestSubResource extends Resource
  endpoint: "/subresource/:id"

class OtherTestSubResource extends Resource
  endpoint: "/subresource2/:id"

createMockAttrs = fixtures.createMockAttrs

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
