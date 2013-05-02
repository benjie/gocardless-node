querystring = require 'querystring'
crypto = require 'crypto'

module.exports = {
  percentEncode: (string) ->
    return encodeURI(string)

  toQuery: (obj) ->
    ###Create a query string from a list or dictionary###
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
    params = JSON.stringify JSON.parse data.copy()
    sig = params.signature
    delete params.signature
    valid_sig = @generateSignature(params, secret)
    return sig is valid_sig

  camelize: (to_uncamel) ->
    return to_uncamel.replace /_[a-z]/, (m) -> m.substr(1).toUpperCase()

  singularize: (to_sing) ->
    return to_sing.replace(/s$/, "")
}
