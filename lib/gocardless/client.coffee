gocardless = require '../'

utils = gocardless.utils
{ClientError, SignatureError} = gocardless.exceptions

API_PATH = '/api/v1'
BASE_URLS = {
  'production': 'https://gocardless.com'
  'sandbox': 'https://sandbox.gocardless.com'
}

module.exports = class GoCardlessClient
  constructor: ({@app_id, @app_secret, @access_token, @merchant_id, @environment}) ->
    @environment ?= process.ENV['GOCARDLESS_ENVIRONMENT']

    throw new Error("app_id is required") unless @app_id?
    throw new Error("app_secret is required") unless @app_secret?
    throw new Error("access_token is required") unless @access_token?
    throw new Error("merchant_id is required") unless @merchant_id?
    throw new Error("environment must be 'production' or 'sandbox'") unless ['production', 'sandbox'].indexOf(@environment) isnt -1

    @base_url = BASE_URLS[environment]

  apiGet: (path, callback) ->
    ###
    Issue an GET request to the API server.

    :param path: the path that will be added to the API prefix
    ###
    return @_request('get', path, null, callback)

  apiPost: (path, data, callback) ->
    ###Issue a POST request to the API server

    :param path: The path that will be added to the API prefix
    :param data: The data to post to the url.
    ###
    return @_request('post', path, data, callback)

  apiPut: (path, data={}, callback) ->
    ###Issue a PUT request to the API server

    :param path: The path that will be added to the API prefix
    :param data: The data to put to the url.
    ###
    return @_request('put', path, data, callback)

  apiDelete: (path, callback) ->
    ###Issue a delete to the API server.

    :param path: the path that will be added to the API prefix
    :param params: query string parameters
    ###
    return @_request('delete', path, null, callback)

  _request: (method, path, data, callback) ->
    ###
    Send a request to the GoCardless API servers.

    :param method: the HTTP method to use (e.g. +:get+, +:post+)
    :param path: the path fragment of the URL
    ###
    request_url = @base_url + API_PATH + path
    request = new Request(method, request_url)
    console.log("Executing request to #{request_url}")

    request.useBearerAuth(@access_token)

    request.setPayload(data)
    request.perform (err, details) ->
      if err or details?.error?
        return callback new ClientError "Error calling API, message was: "+(details?.error ? err.message)
      else
        return callback null, details

  merchant: (callback) ->
    ###
    Returns the current Merchant's details.
    ###
    merchant_url = '/merchants/%s' % @_merchant_id
    @apiGet merchant_url, (err, details) ->
      return callback err if err
      callback null, new Merchant details

  user: (id) ->
    ###
    Find a user by id

    :param id: The users id
    ###
    return User.findWithClient(id, self)

  preAuthorization: (id) ->
    ###
    Find a pre authorization with id `id`

    :params id: The pre authorization id
    ###
    return PreAuthorization.findWithClient(id, self)

  subscription: (id) ->
    ###
    Returns a single subscription

    :param id: The subscription id, String
    ###
    return Subscription.findWithClient(id, self)

  bill: (id) ->
    ###
    Find a bill with id `id`
    ###
    return Bill.findWithClient(id, self)

  createBill: (amount, pre_auth_id, name=null, description=null) ->
    ###Creates a new bill under an existing pre_authorization

    :param amount: The amount to bill
    :param preAuthId: The id of an existing pre_authorization which
      has not expire
    :param name: A name for this bill
    :param description: A description for this bill

    ###
    return Bill.createUnderPreauth(amount, pre_auth_id, self, name=name, description=description)

  newSubscriptionUrl: (amount, interval_length, interval_unit, name=null, description=null, interval_count=null, start_at=null, expires_at=null, redirect_uri=null, cancel_uri=null, state=null, user=null, setup_fee=null) ->
    ###Generate a url for creating a new subscription

    :param amount: The amount to charge each time
    :param intervalLength: The length of time between each charge, this
      is an integer, the units are specified by interval_unit.
    :param intervalUnit: The unit to measure the interval length, must
      be one of "day", "week" or "month"
    :param name: The name to give the subscription
    :param description: The description of the subscription
    :param intervalCount: The Calculates expires_at based on the number
      of intervals you would like to collect. If both interval_count and
      expires_at are specified the expires_at parameter will take
      precedence
    :param expiresAt: When the subscription expires, should be a datetime
      object.
    :param startsAt: When the subscription starts, should be a datetime
      object
    :param redirectUri: URI to redirect to after the authorization process
    :param cancelUri: URI to redirect the user to if they cancel
      authorization
    :param state: String which will be passed to the merchant on
      redirect.
    :param user: A dictionary which will be used to prepopulate the sign
      up form the user sees, this can contain keys

      - `first_name`
      - `last_name`
      - `email`

    :param setupFee: A one off payment which will be taken at the start
      of the subscription.
    ###
    params = urlbuilder.SubscriptionParams(
      amount, @_merchant_id,
      interval_length, interval_unit, name=name,
      description=description, interval_count=interval_count,
      expires_at=expires_at, start_at=start_at, user=user,
      setup_fee=setup_fee
    )
    builder = urlbuilder.UrlBuilder(self)
    return builder.buildAndSign(params, redirect_uri=redirect_uri,
                    cancel_uri=cancel_uri, state=state)

  newBillUrl: (amount, name=null, description=null, redirect_uri=null, cancel_uri=null, state=null, user=null) ->
    ###Generate a url for creating a new bill

    :param amount: The amount to bill the customer
    :param name: The name of the bill
    :param description: The description of the bill
    :param redirectUri: URI to redirect to after the authorization process
    :param cancelUri: URI to redirect the user to if they cancel
      authorization
    :param state: String which will be passed to the merchant on
      redirect.
    :param user: A dictionary which will be used to prepopulate the sign
      up form the user sees, this can contain keys

      - `first_name`
      - `last_name`
      - `email`


    ###
    params = urlbuilder.BillParams(amount, @_merchant_id, name=name,
                     description=description, user=user)
    builder = urlbuilder.UrlBuilder(self)
    return builder.buildAndSign(params, redirect_uri=redirect_uri,
                    cancel_uri=cancel_uri, state=state)

  newPreauthorizationUrl: (max_amount, interval_length, interval_unit, expires_at=null, name=null, description=null, interval_count=null, calendar_intervals=null, redirect_uri=null, cancel_uri=null, state=null, user=null, setup_fee=null) ->
    ###Get a url for creating new pre_authorizations

    :param maxAmount: A float which is the maximum amount for this
      pre_authorization
    :param intervalLength: The length of this pre_authorization
    :param intervalUnit: The units in which the interval_length
      is measured, must be one of
      - "day"
      - "week"
      - "month"
    :param expiresAt: The date that this pre_authorization will
      expire, must be a datetime object which is in the future.
    :param name: A short string which is the name of the pre_authorization
    :param description: A longer string describing what the
      pre_authorization is for.
    :param intervalCount: calculates expires_at based on the number of
      payment intervals you would like the resource to have. Must be a
      positive integer greater than 0. If you specify both an
      interval_count and an expires_at argument then the expires_at
      argument will take precedence.
    :param calendarIntervals: Describes whether the interval resource
      should be aligned with calendar weeks or months, default is False
    :param redirectUri: URI to redirect to after the authorization process
    :param cancelUri: URI to redirect the user to if they cancel
      authorization
    :param state: String which will be passed to the merchant on
      redirect.
    :param user: A dictionary which will be used to prepopulate the sign
      up form the user sees, this can contain keys

      - `first_name`
      - `last_name`
      - `email`
    :param setupFee: A one off payment which will be taken at the start
      of the subscription.

    ###
    params = urlbuilder.PreAuthorizationParams(
      max_amount, @_merchant_id, interval_length, interval_unit,
      expires_at=expires_at, name=name, description=description,
      interval_count=interval_count, user=user,
      calendar_intervals=calendar_intervals, setup_fee=setup_fee
    )
    builder = urlbuilder.UrlBuilder(self)
    return builder.buildAndSign(params, redirect_uri=redirect_uri,
                    cancel_uri=cancel_uri, state=state)

  # Create an alias to new_preauthorization_url to conform to the
  # documentation
  @::newPreAuthorizationUrl = @::newPreauthorizationUrl

  confirmResource: (params) ->
    ###Confirm a payment

    This send a post request to the confirmation URI for a payment.
    params should contain these elements from the request
    - resource_uri
    - resource_id
    - resource_type
    - signature
    - state (if any)
    ###
    keys = ["resource_uri", "resource_id", "resource_type", "state"]
    to_check = dict([[k, v] for k, v in params.items() if k in keys])
    signature = generateSignature(to_check, @_app_secret)
    if not signature == params["signature"]
      raise SignatureError("Invalid signature when confirming resource")
    auth_string = base64.b64encode("{0}:{1}".format(
      @app_id, @_app_secret))
    to_post = {
      "resource_id": params["resource_id"],
      "resource_type": params["resource_type"],
    }
    auth_details = [@app_id, @_app_secret]
    @apiPost("/confirm", to_post, auth=auth_details)

  newMerchantUrl: (redirect_uri, state=null, merchant=null) ->
    ###Get a URL for managing a new merchant

    This method creates a URL which partners should redirect
    merchants to in order to obtain permission to manage their GoCardless
    payments.

    :param redirectUri: The URI where the merchant will be sent after
      authorizing.
    :param state: An optional string which will be present in the request
      to the redirect URI, useful for tracking the user.
    :param merchant: A dictionary which will be used to prepopulate the
      merchant sign up page, can contain any of the keys

      - "name"
      - "phone_number"
      - "description"
      - "merchant_type" (either 'business', 'charity' or 'individual')
      - "company_name"
      - "company_registration"
      - "user" which can be a dictionary containing the keys

      - "first_name"
      - "last_name"
      - "email"

    ###
    params = {
      "client_id": @app_id,
      "redirect_uri": redirect_uri,
      "scope": "manage_merchant",
      "response_type": "code",
    }
    if state
      params["state"] = state
    if merchant
      params["merchant"] = merchant
    return "{0}/oauth/authorize?{1}".format(@base_url,
                        toQuery(params))

  fetchAccessToken: (redirect_uri, authorization_code) ->
    ###Fetch the access token for a merchant

    Takes the authorization code obtained from a merchant redirect
    and the redirect_uri used in that same redirect and fetches the
    corresponding access token. The access token is returned and also
    set on the client so the client can then be used to make api calls
    on behalf of the merchant.

    :param redirectUri: The redirect_uri used in the request which
      obtained the authorization code, must match exactly.
    :param authorizationCode: The authorization code obtained in the
      previous part of the process.

    ###
    params = {
      "client_id": @app_id,
      "code": authorization_code,
      "redirect_uri": redirect_uri,
      "grant_type": "authorization_code"
    }
    query = toQuery(params)
    url = "/oauth/access_token?#{query}"
    # have to use _request so we don't add apiBase to the url
    auth_details = [@app_id, @_app_secret]
    result = @_request("post", url, auth=auth_details)
    @_access_token = result["access_token"]
    @_merchant_id = result["scope"].split(":")[1]
    return @_access_token

  validateWebhook: (params) ->
    ###Check whether a webhook signature is valid

    Takes a dictionary of parameters, including the signature
    and returns a boolean indicating whether the signature is
    valid.

    :param params: A dictionary of data to validate, must include
      the key "signature"
    ###
    return signatureValid(params, @_app_secret)

