gocardless = require '../src'
{utils, urlbuilder} = gocardless
{ClientError, SignatureError, ValueError} = gocardless.exceptions
{Bill, Merchant, PreAuthorization, Resource, Subscription, User} = gocardless.resources

expiringLimit = (createParams) ->
  describe 'ExpiringLimit', ->
    it 'interval length is positive', ->
      pars = createParams(10, "1321230", 1, "day")
      (->
        pars = createParams(10, "1123210", -1, "day")
      ).should.throw ValueError

    it 'interval unit is valid', ->
      for interval_unit in ["day", "week", "month"]
        pars = createParams(10, 10, "11235432", interval_unit)
      (->
        pars = createParams(10, 10, "1432233123", "invalid")
      ).should.throw ValueError

    _futureDateTester = (argname) ->
      invalid_date = new Date(+new Date() - 100)
      valid_date = new Date(+new Date() + 2000)
      o = {}
      o[argname] = valid_date
      par1 = createParams(10, 10, "23423421", "day", o)
      (->
        o = {}
        o[argname] = invalid_date
        par1 = createParams(10, 10, "2342341", "day", o)
      ).should.throw ValueError

    it 'expires at in future', ->
      _futureDateTester("expires_at")

    it 'interval count positive', ->
      (->
        createParams(10, 10, "merchid", "day", {interval_count:-1})
      ).should.throw ValueError

describe 'PreAuthParams', ->

  defaultArgsConstruct = (extra_options) ->
    ###
    For testing optional arguments, builds the param object with valid
    required arguments and adds optionl arguments as keywords from
    `extra_options`

    :param extra_options: Extra optional keyword arguments to pass to
    the constructor.
    ###
    return new urlbuilder.PreAuthorizationParams(12, "3456", 6, "month", extra_options)

  createParams = (a, b, c, d, kwargs) ->
    tmp = class extends urlbuilder.PreAuthorizationParams
      constructor: ->
        super a, b, c, d, kwargs
    return new tmp

  expiringLimit createParams

  it 'max amount is positive', ->
    (->
      new urlbuilder.PreAuthorizationParams(-1, "1232532", 4, "month")
    ).should.throw ValueError

  it 'interval length is a positive integer', ->
    (->
      new urlbuilder.PreAuthorizationParams(12, "!2343", -3, "month")
    ).should.throw ValueError

  it 'interval unit is one of accepted', ->
    for unit_type in ["month", "day", "week"]
      pa = new urlbuilder.PreAuthorizationParams(12, "1234", 3, unit_type)
    (->
      new urlbuilder.PreAuthorizationParams(21, "1234", 4, "soem other unit")
    ).should.throw ValueError

  it 'expires at is later than now', ->
    earlier = new Date(+new Date() - 1)
    (->
      defaultArgsConstruct({"expires_at":earlier})
    ).should.throw ValueError

  it 'interval count is postive integer', ->
    (->
      defaultArgsConstruct({"interval_count":-1})
    ).should.throw ValueError

describe 'PreAuthParamsToDict', ->
  all_params = {
    "max_amount":12,
    "interval_unit":"day",
    "interval_length":10,
    "merchant_id":"1234435",
    "name":"aname",
    "description":"adesc",
    "interval_count":123,
    "expires_at":new Date("2020-01-01"),
    "calendar_intervals":true
  }

  required_keys = [ "max_amount", "interval_unit", "interval_length", "merchant_id"]

  createFromParamsDict = (in_params) ->
    params = Object.create(in_params)
    max_amount = params.max_amount
    delete params.max_amount
    merchant_id = params.merchant_id
    delete params.merchant_id
    interval_length = params.interval_length
    delete params.interval_length
    interval_unit = params.interval_unit
    delete params.interval_unit

    pa = new urlbuilder.PreAuthorizationParams(max_amount,  merchant_id, interval_length, interval_unit, params)
    return pa

  assertInverse = (keys) ->
    params = {}
    params[k] = v for k, v of all_params when keys.indexOf(k) isnt -1
    pa = createFromParamsDict(params)
    params.should.eql pa.toDict()

  it 'to dict all params', ->
    assertInverse(Object.keys all_params)

  it 'to dict only required', ->
    assertInverse(required_keys)

describe 'BillParams', ->

  createParams = (a, b, kwargs) ->
    tmp = class extends urlbuilder.BillParams
      constructor: ->
        super a, b, kwargs
    return new tmp

  it 'amount is positive', ->
    params = createParams(10, "merchid")
    (->
      par2 = createParams(-1, "merchid")
    ).should.throw ValueError

  it 'to dict required', ->
    pars = createParams(10, "merchid")
    res = pars.toDict()
    expected = {"amount":10, "merchant_id":"merchid"}
    res.should.eql expected

  it 'to dict optional', ->
    pars = createParams(10, "merchid", {name:"aname", description:"adesc"})
    res = pars.toDict()
    expected = {
      "amount":10,
      "name":"aname",
      "description":"adesc",
      "merchant_id":"merchid"
    }
    res.should.eql expected

  it 'resource name is bills', ->
    pars = new urlbuilder.BillParams(10, "merchid")
    pars.resource_name.should.equal "bills"

describe 'SubscriptionParams', ->

  createParams = (a, b, c, d, kwargs) ->
    tmp = class extends urlbuilder.SubscriptionParams
      constructor: ->
        super a, b, c, d, kwargs
    return new tmp

  expiringLimit createParams

  it 'setup fee', ->
    pars = createParams(10, "merchid", 10, "day", {setup_fee:20})
    expected = {
        "merchant_id": "merchid",
        "amount": 10,
        "interval_length": 10,
        "interval_unit" : "day",
        "setup_fee": 20
        }
    expected.should.eql pars.toDict()

  it 'start at in future', ->
    valid_date = new Date(+new Date() + 200)
    invalid_date = new Date(+new Date() - 100)
    par1 = createParams(10,"merchid", 10, "day", {start_at:valid_date})
    (->
      par2 = createParams(10, "merchid", 10, "day", {start_at:invalid_date})
    ).should.throw ValueError

  it 'expires at after start at', ->
    date1 = new Date(+new Date() + 100)
    date2 = new Date(+new Date() + 200)
    par1 = createParams(10, "merchid", 10, "day", {expires_at:date2, start_at:date1})
    (->
      par2 = createParams(10, "merchid", 10, "day", {expires_at:date1, start_at:date2})
    ).should.throw ValueError

  it 'to dict only required', ->
    expected = {
      "merchant_id":"merchid",
      "amount":10,
      "interval_length":10,
      "interval_unit":"day"
    }
    pars = createParams(10, "merchid", 10, "day")
    expected.should.eql pars.toDict()

  it 'to dict all', ->
    start_at = new Date(+new Date() + 1000)
    expires_at = new Date(+new Date() + 2000)
    expected = {
      "merchant_id":"merchid",
      "amount":10,
      "interval_length":10,
      "interval_unit":"day",
      "interval_count":5,
      "start_at":start_at.toISOString()
      "expires_at":expires_at.toISOString()
      "name":"aname",
      "description":"adesc",
    }
    par = createParams(10, "merchid", 10, "day", {start_at:start_at, expires_at:expires_at, interval_count:5, name:"aname", description:"adesc"})
    expected.should.eql par.toDict()

describe 'PrepopData', ->

  mock_prepop = {
    "first_name": "Tom",
    "last_name": "Blomfield",
    "email": "tomgocardless.com"
  }

  assertPrepop = (params) ->
    params.toDict()["user"].should.equal mock_prepop

  it 'bill params', ->
    params = new urlbuilder.BillParams(10, "amerchid", {user:mock_prepop})
    assertPrepop(params)

  it 'sub params', ->
    params = new urlbuilder.SubscriptionParams(10, "merchid", 3, "day", {user:mock_prepop})
    assertPrepop(params)

  it 'pre auth params', ->
    params = new urlbuilder.PreAuthorizationParams(10, "amerchid", 5, "day", {user:mock_prepop})
    assertPrepop(params)
