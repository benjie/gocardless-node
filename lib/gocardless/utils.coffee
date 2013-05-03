querystring = require 'querystring'
crypto = require 'crypto'

module.exports = {
  percentEncode: (string) ->
    result = encodeURIComponent(string)
    result = result.replace /[*!'()]/g, (char) ->
      return "%#{char.charCodeAt(0).toString(16).toUpperCase()}"
    return result

  toQueryObject: (o) ->
    ###
    Changes array keys from {"example": [...]} to {"example[]": [...]}
    and sorts the keys lexicographically
    ###
    keys = Object.keys o
    keys.sort()
    result = {}
    for key in keys
      val = o[key]
      if Array.isArray val
        result[key+'[]'] = val
      else if typeof val is 'object'
        obj = @toQueryObject val
        for k,v of obj
          result["#{key}[#{k}]"] = v
      else
        result[key] = val
    return result

  toQuery: (obj) ->
    ###Create a query string from a list or dictionary###
    obj = @toQueryObject obj
    return querystring.stringify obj

  generateSignature: (data, secret) ->
    ###
    signature takes a dict / tuple /string
    and your application's secret, returning a HMAC-SHA256
    digest of the data.
    ###
    hmac = crypto.createHmac('sha256', new Buffer(secret, 'utf8'))
    data = @toQuery data
    hmac.update data
    return hmac.digest 'hex'

  signatureValid: (data, secret) ->
    params = JSON.parse JSON.stringify data
    sig = params.signature
    delete params.signature
    valid_sig = @generateSignature(params, secret)
    return sig is valid_sig

  camelize: (to_uncamel) ->
    return to_uncamel.replace /(?:^|_)([a-z])/g, (match, m1) -> m1.toUpperCase()

  singularize: (to_sing) ->
    return to_sing.replace(/s$/, "")
}
