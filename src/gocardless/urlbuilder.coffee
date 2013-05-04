gocardless = require '../'
utils = gocardless.utils
ValueError = gocardless.exceptions.ValueError

nonce = ->
  letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+/"
  n = ""
  for i in [0..50]
    n += letters[Math.floor(Math.random()*letters.length)]
  return n

class UrlBuilder
  ###Handles correctly encoding and signing api urls###

  constructor: (client) ->
    ###Create a new UrlBuilder

    :param client: an instance of `gocardless.Client` which will
    be used to sign urls.
    ###
    @client = client

  buildAndSign: (params, {state, redirect_uri, cancel_uri}={}) ->
    ###Builds a url and returns it as a string

    :param params: A Params class corresponding to the resource for which
    you wish to create a url. For example, to create a Subscription url
    pass an instance of SubscriptionParams.
    :param state: The state argument to be encoded in the query string.
    :param redirect_uri: The redirect uri the user will be sent to after
    the resource has been created.
    :param cancel_uri: The uri the user will be redirected to if they
    cancel the resource creation
    ###
    param_dict = {}
    resource_name = utils.singularize(params.resource_name)
    param_dict[resource_name] = JSON.parse(JSON.stringify(params.toDict()))
    if state
      param_dict["state"] = state
    if redirect_uri
      param_dict["redirect_uri"] = redirect_uri
    if cancel_uri
      param_dict["cancel_uri"] = cancel_uri
    param_dict["client_id"] = @client.app_id
    param_dict["timestamp"] = new Date().toISOString()
    param_dict["nonce"] = nonce()

    signature = utils.generateSignature(param_dict, @client.app_secret)
    param_dict["signature"] = signature

    url = "#{@client.base_url}/connect/#{params.resource_name}/new?#{utils.toQuery(param_dict)}"
    return url

class BasicParams
  constructor: (amount, merchant_id, {name, description, user}={}) ->
    unless amount > 0
      throw new ValueError("amount must be positive, value passed was #{amount}")
    @amount = amount
    @merchant_id = merchant_id

    if name
      @name = name

    if user
      @user = user

    if description
      @description = description
    @attrnames = ["amount", "name", "description", "merchant_id", "user"]

  toDict: ->
    result = {}
    for attrname in @attrnames
      val = @[attrname]
      if val
        result[attrname] = val
    return result

class PreAuthorizationParams
  constructor: (max_amount, merchant_id, interval_length, interval_unit, {expires_at, name, description, interval_count, calendar_intervals, user, setup_fee}={}) ->
    @merchant_id = merchant_id
    @resource_name = "pre_authorizations"

    if user
      @user = user

    unless max_amount > 0
      throw new ValueError("max_amount must be positive value passed was #{max_amount}")
    @max_amount = max_amount

    @setup_fee = setup_fee

    unless interval_length > 0
      throw new ValueError("interval_length must be positive, value passed was #{interval_length}")
    @interval_length = interval_length

    valid_units = ["month", "day", "week"]
    if interval_unit not in valid_units
      message = "interval_unit must be one of #{valid_units}, value passed was #{interval_unit}"
      throw new ValueError(message)
    @interval_unit = interval_unit

    if expires_at
      if (+expires_at - +new Date()) < 0
        time_str = expires_at.toISOString()
        throw new ValueError("expires_at must be in the future, date passed was #{time_str}")
      @expires_at = expires_at
    else
      @expires_at = null

    if interval_count
      if interval_count < 0
        throw new ValueError("interval_count must be positive value passed was #{interval_count}")
      @interval_count = interval_count
    else
      @interval_count = null

    @name = name ? null
    @description = description ? null
    @calendar_intervals = null
    if calendar_intervals
      @calendar_intervals = calendar_intervals

  toDict: ->
    result = {}
    attrnames = [
      "merchant_id", "name", "description", "interval_count",
      "interval_unit", "interval_length", "max_amount",
      "calendar_intervals", "expires_at", "user", "setup_fee"
    ]
    for attrname in attrnames
      val = @[attrname]
      if val
        result[attrname] = val
    return result

class BillParams extends BasicParams

  constructor: (amount, merchant_id, {name, description, user}={}) ->
    super
    @resource_name = "bills"

class SubscriptionParams extends BasicParams

  constructor: (amount, merchant_id, interval_length, interval_unit, {name, description, start_at, expires_at, interval_count, user, setup_fee}={}) ->
    super amount, merchant_id, {name, description, user}
    @resource_name = "subscriptions"
    @merchant_id = merchant_id

    unless interval_length > 0
      throw new ValueError("interval_length must be positive, value passed was #{interval_length}")
    @interval_length = interval_length

    valid_units = ["month", "day", "week"]
    if interval_unit not in valid_units
      message = "interval_unit must be one of #{valid_units}, value passed was #{interval_unit}"
      throw new ValueError(message)
    @interval_unit = interval_unit

    if expires_at
      @checkDateInFuture(expires_at, "expires_at")
      @expires_at = expires_at

    if start_at
      @checkDateInFuture(start_at, "start_at")
      @start_at = start_at

    if expires_at and start_at
      if (expires_at - start_at) < 0
        throw new ValueError("start_at must be before expires_at")

    if interval_count
      if interval_count < 0
        throw new ValueError("interval_count must be positive value passed was #{interval_count}")
      @interval_count = interval_count

    @name = name ? null
    @description = description ? null
    @setup_fee = setup_fee

    @attrnames = @attrnames.concat([
      "description", "interval_count", "interval_unit",
      "interval_length", "expires_at", "start_at", "setup_fee", "user"
    ])

  checkDateInFuture: (date, argname) ->
    if (+date - +new Date()) < 0
      throw new ValueError("#{argname} must be in the future, date passed was#{date.toISOString()}")

  toDict: ->
    result = {}
    for attrname in @attrnames
      val = @[attrname]
      if val
        if attrname in ["start_at", "expires_at"]
          result[attrname] = val.toISOString()
        else
          result[attrname] = val
    return result

module.exports = {UrlBuilder, BasicParams, PreAuthorizationParams, BillParams, SubscriptionParams}
