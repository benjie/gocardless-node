details = require '../package.json'
version = details.version

#(Bill, Subscription, PreAuthorization, User, Merchant)
#from gocardless.resources import (Merchant, Subscription, Bill, PreAuthorization, User)

exports.getVersion = -> version
exports.exceptions = require './gocardless/exceptions'
exports.utils = require './gocardless/utils'
exports.resources = require './gocardless/resources'
exports.urlbuilder = require './gocardless/urlbuilder'
exports.Request = require('./gocardless/request')
exports.Client = require('./gocardless/client')
