mongoose = require("mongoose")
crypto = require("crypto")
utils  = require './utils'

Schema = mongoose.Schema
ObjectId = Schema.ObjectId

validatePresenceOf = (value) ->
  value and value.length


###
Model: User
###
User = new Schema(
  email:
    type: String
    validate: [validatePresenceOf, "an email is required"]
    index:
      unique: true

  hashed_password: String
  salt: String
)
User.virtual("id").get ->
  @_id.toHexString()

User.virtual("password").set((password) ->
  @_password = password
  @salt = @makeSalt()
  @hashed_password = @encryptPassword(password)
).get ->
  @_password

User.method "authenticate", (plainText) ->
  @encryptPassword(plainText) is @hashed_password

User.method "makeSalt", ->
  Math.round((new Date().valueOf() * Math.random())) + ""

User.method "encryptPassword", (password) ->
  crypto.createHmac("sha1", @salt).update(password).digest "hex"

User.pre "save", (next) ->
  unless validatePresenceOf(@password)
    next new Error("Invalid password")
  else
    next()

###
Model: LoginToken

Used for session persistence.
###
LoginToken = new Schema(
  email:
    type: String
    index: true

  series:
    type: String
    index: true

  token:
    type: String
    index: true
)

LoginToken.method "randomToken", ->
  Math.round((new Date().valueOf() * Math.random())) + ""

LoginToken.pre "save", (next) ->

  # Automatically create the tokens
  @token = @randomToken()
  @series = @randomToken()  if @isNew
  next()

LoginToken.virtual("id").get ->
  @_id.toHexString()

LoginToken.virtual("cookieValue").get ->
  JSON.stringify
    email: @email
    token: @token
    series: @series

Todo = new Schema(
  user_id: String
  content: String
  updated_at: Date
)

mongoose.model "User", User
mongoose.model "LoginToken", LoginToken
mongoose.model "Todo", Todo

host = utils.confKey 'mongodb.host'
base = utils.confKey 'mongodb.base'
db = mongoose.connect 'mongodb://'+host+'/'+base, (err)->
  throw err if err
  console.log 'Successfully connected to MongoDB'
