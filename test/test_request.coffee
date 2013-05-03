gocardless = require '../lib'
should = require 'should'
nock = require 'nock'

TESTHOST = "https://test.local"

request = null
api = nock(TESTHOST)

describe 'Request', ->
  before ->
    PATH = "/api/v1/blah/test/thing"
    request = new gocardless.Request('get', "#{TESTHOST}#{PATH}")
    api.persist()
      .get(PATH).reply(200, '{"a":"b"}')
      .post(PATH).reply(200, '{"a":"b"}')

  it 'should allow valid methods', ->
    for method in ['get', 'post', 'put']
      request._validMethod(method).should.be.true

  it 'should disallow invalid methods', ->
    request._validMethod('fake_method').should.be.false

  it 'should set Authorization header for bearer auth', ->
    request.useBearerAuth('token')
    request._opts['headers']['Authorization'].should.equal 'bearer token'

  it 'should set auth details', ->
    request.useHttpAuth('user', 'pass')
    request._opts['auth'].should.eql ['user', 'pass']

  describe 'payload', ->
    it 'should ignore null payloads', ->
      request.setPayload(null)
      request._opts['headers'].should.not.have.key 'Content-Type'
      request._opts.should.not.have.key 'data'

    it 'should set Content-Type', ->
      request.setPayload({'a': 'b'})
      request._opts['headers']['Content-Type'].should.equal 'application/json'

    it 'should encode the payload', ->
      request.setPayload({'a': 'b'})
      request._opts['data'].should.equal '{"a":"b"}'

  it 'should perform callback once', (done) ->
    # XXX: Ensure callback is called but once
    callback = (err, res) ->
      should.not.exist(err)
      should.exist(res)
      res.should.eql {"a":"b"}
      done()
    request.perform callback

  it 'should perform callback once for POST too', (done) ->
    request._method = 'post'
    callback = (err, res) ->
      should.not.exist(err)
      should.exist(res)
      res.should.eql {"a":"b"}
      done()
    request.perform callback
