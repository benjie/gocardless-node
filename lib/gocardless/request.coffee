https = require 'https'
nodeUrl = require 'url'
gocardless = require '../'

utils = gocardless.utils
{ClientError, SignatureError} = gocardless.exceptions

class Request
  constructor: (method, url) ->
    @_method = method
    @_url = url
    headers = {}
    headers["Accept"] = "application/json"
    lib_version = gocardless.getVersion()
    headers["User-Agent"] = "gocardless-node/#{lib_version}"
    @_opts = {"headers": headers}

    if not @_validMethod(method)
      raise ValueError("Invalid method #{method}")

  _validMethod: (method) ->
    return method in ['get', 'post', 'put']

  useHttpAuth: (username, password) ->
    @_opts.auth = [username, password]

  useBearerAuth: (token) ->
    auth_header = "bearer #{token}"
    @_opts.headers['Authorization'] = auth_header

  setPayload: (payload) ->
    if payload isnt null
      # Set the payload type - always JSON
      @_opts.headers['Content-Type'] = 'application/json'
      # And JSON encode the data
      @_opts.data = JSON.stringify(payload)

  perform: (callback) ->
    parsed = nodeUrl.parse @_url
    options = {
      hostname: parsed.host
      path: parsed.pathname
      method: @_method
      headers: @_opts.headers
    }
    options.auth = @_opts.auth if @_opts.auth?.length

    req = https.request options, (res) ->
      data = ""
      res.setEncoding 'utf8'
      res.on 'data', (chunk) -> data += chunk
      res.on 'end', ->
        try
          decoded = JSON.parse data
        if decoded
          return callback null, decoded
        else
          return callback new ClientError("JSON parsing failed")
    req.on 'error', (e) ->
      return callback e
    if @_opts.data
      req.write @_opts.data
    req.end()
    return

module.exports = Request
