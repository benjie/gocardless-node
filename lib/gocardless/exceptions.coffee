class GoCardlessError extends Error
  constructor: (@message) ->
    super
class ClientError extends GoCardlessError
class SignatureError extends GoCardlessError
class ValueError extends GoCardlessError

module.exports = {ClientError, SignatureError, ValueError}
