class GoCardlessError extends Error
class ClientError extends GoCardlessError
class SignatureError extends GoCardlessError

module.exports = {ClientError, SignatureError}
