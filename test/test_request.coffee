gocardless = require '../lib'

request = null

describe 'Request', ->
  before ->
    request = new gocardless.Request('get', 'http://test.com')

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

###
  testSetPayloadEncodesPayload: ->
    request.setPayload({'a': 'b'})
    @assertEqual(request._opts['data'], '{"a": "b"}')

  @mock.patch('gocardless.request.requests')
  testPerformCallsGetForGets: (mock_requests) ->
    mock_requests.get.return_value.content = '{"a": "b"}'
    request.perform()
    mock_requests.get.assertCalledOnceWith(mock.ANY, headers=mock.ANY)

  @mock.patch('gocardless.request.requests')
  testPerformCallsPostForPosts: (mock_requests) ->
    mock_requests.post.return_value.content = '{"a": "b"}'
    request._method = 'post'
    request.perform()
    mock_requests.post.assertCalledOnceWith(mock.ANY, headers=mock.ANY)

  @mock.patch('gocardless.request.requests.get')
  testPerformDecodesJson: (mock_get) ->
    response = mock.Mock()
    response.content = '{"a": "b"}'
    mock_get.return_value = response
    @assertEqual(request.perform(), {'a': 'b'})
###
