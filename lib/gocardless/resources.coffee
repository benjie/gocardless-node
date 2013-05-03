#import datetime
#import re
#import sys
#import types
#
#import utils
#import gocardless
gocardless = require '../'

ClientError = gocardless.exceptions.ClientError

_getKlassFromName = (name) ->
  klassName = utils.singularize utils.camelize name
  return module.exports[klassName]

class Resource
  ###A GoCardless resource

  Subclasses of `Resource` define class attributes to specify how
  the resource is fetched and represented.

  The class attribute `endpoint` is the path to the resource on the server.

  The class attribute `date_fields` names fields which will be converted
  into `datetime.datetime` objects on construction.

  The class attribute `reference_fields` names fields which are uris to other
  resources and will be converted into functions which can be called to
  retrieve those resources.
  ###

  date_fields: ["created_at"]
  reference_fields: []

  constructor: (in_attrs, client) ->
    ###Construct a resource

    :param inAttrs: A dictionary of attributes, usually obtained from a
    JSON response.
    :param client: an instance of gocardless.Client
    ###
    attrs = JSON.parse(JSON.stringify(in_attrs))
    @_raw_attrs = JSON.parse(JSON.stringify(attrs))
    @id = attrs["id"]
    @client = client
    ###
    if "sub_resource_uris" in attrs
      #For each subresource_uri create a method which grabs data
      #from the URI and uses it to instantiate the relevant class
      #and return it.
      for name, uri in attrs.pop("sub_resource_uris").items()
        path = re.sub(".*"+"/api/v1", "", uri)
        sub_klass = _getKlassFromName(name)
        createGetResourceFunc: (the_path, the_klass) ->
          # In python functions close over their environment so in
          # order to create the correct closure we need a function
          # creator, see
          # http://stackoverflow.com/questions/233673/
          #     lexical-closures-in-python/235764#235764
          getResources: (inst) ->
            data = inst.client.apiGet(the_path)
            return [theKlass(attrs, @client) for attrs in data]
          return get_resources
        res_func = createGetResourceFunc(path, sub_klass)
        func_name = "#{name}"
        res_func.name = func_name
        setattr(func_name,
            types.MethodType(res_func, self, @__class__))
    ###

    for fieldname in @date_fields
      val = attrs[fieldname]
      delete attrs[fieldname]
      if val isnt null
        @[fieldname] = new Date val
      else
        @[fieldname] = null

    ###
    for fieldname in @reference_fields
      id = attrs[fieldname]
      delete attrs[fieldname]
      createGetFunc: (the_klass, the_id) ->
        getReferencedResource: (inst) ->
          return the_klass.findWithClient(the_id, @client)
        return get_referenced_resource
      name = fieldname.replace("_id", "")
      klass = @_getKlassFromName(name)
      func = createGetFunc(klass, id)
      setattr(name, types.MethodType(func, self, @__class__))
    ###

    for own key, value of attrs
      @[key] = value

  getEndpoint: ->
    return @endpoint.replace(":id", @id)

  __eq__: (other) ->
    if isinstance(other, @__class__)
      return @_raw_attrs == other._raw_attrs
    return False

  __hash__: ->
    return hash(@_raw_attrs["id"])

  @findWithClient: (id, client, callback) ->
    path = @::endpoint.replace(":id", id)
    client.apiGet path, (err, res) =>
      return callback err if err
      callback null, new @ res

  @find: (cls, id) ->
    if not gocardless.client
      raise ClientError("You must set your account details first")
    return cls.findWithClient(id, gocardless.client)

class Merchant extends Resource
  endpoint: "/merchants/:id"
  date_fields: _super::date_fields.concat ["next_payout_date"]

class Subscription extends Resource
  endpoint: "/subscriptions/:id"
  reference_fields: ["user_id", "merchant_id"]
  date_fields: _super::date_fields.concat ["expires_at", "next_interval_start"]

  cancel: ->
    path = "#{@endpoint.replace(":id", @id)}/cancel"
    @client.apiPut(path)

class PreAuthorization extends Resource
  endpoint: "/pre_authorizations/:id"
  date_fields: _super::date_fields.concat ["expires_at", "next_interval_start"]
  reference_fields: ["user_id", "merchant_id"]

  createBill: (amount, name=null, description=null) ->
    return Bill.createUnderPreauth(amount, @id, @client, name=name, description=description)

  cancel: ->
    path = "#{@endpoint.replace(":id", @id)}/cancel"
    @client.apiPut(path)

class Bill extends Resource
  endpoint: "/bills/:id"
  date_fields: _super::date_fields.concat ["paid_at"]
  reference_fields: ["merchant_id", "user_id"]

  @createUnderPreauth: (amount, pre_auth_id, client, name=null, description=null) ->
    path = "/bills"
    params = {
      "bill": {
        "amount": amount,
        "pre_authorization_id": pre_auth_id
      }
    }
    if name
      params["bill"]["name"] = name
    if description
      params["bill"]["description"] = description
    return Bill(client.apiPost(path, params), client)

  retry: ->
    path = "#{@endpoint.replace(":id", @id)}/retry"
    @client.apiPost(path)

class User extends Resource
  endpoint: "/users/:id"

module.exports = {Bill, Merchant, PreAuthorization, Resource, Subscription, User}
