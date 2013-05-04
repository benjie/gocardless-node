gocardless = require '../src'
should = require 'should'
nock = require 'nock'

utils = gocardless.utils

describe 'Utils', ->

  describe 'percent encode', ->
    it "shouldn't affect empty strings", ->
      utils.percentEncode("").should.equal ""

    it 'doesnt encode lowercase alpha characters', ->
      utils.percentEncode("abcxyz").should.equal "abcxyz"

    it 'doesnt encode uppercase alpha characters', ->
      utils.percentEncode("ABCXYZ").should.equal "ABCXYZ"

    it 'doesnt encode digits', ->
      utils.percentEncode("1234567890").should.equal "1234567890"

    it 'doesnt encode unreserved non alphanum chars', ->
      utils.percentEncode("-._~").should.equal "-._~"

    it 'encodes non ascii alpha characters', ->
      utils.percentEncode("å").should.equal "%C3%A5"

    it 'encodes reserved ascii characters', ->
      utils.percentEncode(" !\"#$%&'()").should.equal "%20%21%22%23%24%25%26%27%28%29"
      utils.percentEncode("*+,/{|}:;").should.equal "%2A%2B%2C%2F%7B%7C%7D%3A%3B"
      utils.percentEncode("<=>?@[\\]^`").should.equal "%3C%3D%3E%3F%40%5B%5C%5D%5E%60"

    it 'encodes other non ascii characters', ->
      utils.percentEncode("支払い").should.equal "%E6%94%AF%E6%89%95%E3%81%84"

  describe 'Signature', ->
    secret = '5PUZmVMmukNwiHc7V/TJvFHRQZWZumIpCnfZKrVYGpuAdkCcEfv3LIDSrsJ+xOVH'
    api_key = ''
    client_id = '4jqkF9tirkr3zfWCgEKxLDy3UmF1sWpHPVm8X69yiB7Lqb63usVOPzrm0jEepc5R'

    it 'hmac', ->
      # make sure our signature function
      # works correctly
      sig = utils.generateSignature({"foo": "bar", "example": [1, "a"]}, secret)
      sig.should.equal '5a9447aef2ebd0e12d80d80c836858c6f9c13219f615ef5d135da408bcad453d'

    it 'validate signature', ->
      params = {"key1":"val1", "key2":"val2"}
      sig = utils.generateSignature(params, secret)
      params["signature"] = sig
      utils.signatureValid(params, secret).should.be.true
      params["signature"] = "123482494523435"
      utils.signatureValid(params, secret).should.be.false

  describe 'Camelize', ->
    it 'camelize multi word', ->
      teststr = "camelize_this_please"
      expected = "CamelizeThisPlease"
      expected.should.equal utils.camelize(teststr)

  describe 'Singularize', ->
    it 'singularize', ->
      to_singularize = "PreAuthorisations"
      expected = "PreAuthorisation"
      expected.should.equal utils.singularize(to_singularize)


