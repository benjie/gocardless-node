class GoCardlessError extends Error
  constructor: -> super
class ClientError extends GoCardlessError
  constructor: -> super
class SignatureError extends GoCardlessError
  constructor: -> super

module.exports = {ClientError, SignatureError}
