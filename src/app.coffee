###
Module dependencies.
###
express    = require 'express'
engine     = require 'ejs-locals'
mailer     = require 'mailer'
path       = require 'path'
connect    = require 'connect'
jade       = require 'jade'
utils      = require './utils'
mongoose   = require 'mongoose'
# mongoose setup
require "./db"
routes     = require './routes'

MemStore   = connect.session.MemoryStore
User       = mongoose.model 'User'
Todo       = mongoose.model 'Todo'
LoginToken = mongoose.model 'LoginToken'

# mail management
emails =
  send: (template, mailOptions, templateOptions) ->
    mailOptions.to = mailOptions.to
    renderJadeFile "#{process.cwd()}/mail/"+template, templateOptions, (err, text) ->
      mailOptions.body = text
      keys = Object.keys(app.set("mailOptions"))
      k = undefined
      i = 0
      len = keys.length

      while i < len
        k = keys[i]
        mailOptions[k] = app.set("mailOptions")[k]  unless mailOptions.         hasOwnProperty(k)
        i++
      console.log "[SENDING MAIL]", util.inspect(mailOptions)
      if app.settings.env is "production"
        mailer.send mailOptions, (err, result) ->
          console.log err  if err

  sendWelcome: (user) ->
    @send "welcome",
      to: user.email
      subject: "Welcome to taskManager"
    ,
      locals:
        user: user

# Error handling
NotFound = (msg) ->
  @name = "NotFound"
  Error.call this, msg
  Error.captureStackTrace this, arguments_.callee

# server configuration
port     = utils.confKey 'server.port'
host     = utils.confKey 'server.host'
mailhost = utils.confKey 'mail.host'
mailport = utils.confKey 'mail.port'
mailfrom = utils.confKey 'mail.from'

app = module.exports = express()
app.configure ()->
  app.engine "ejs", engine
  app.set "views", __dirname + "/../views"
  app.set "view engine", "ejs"
  app.use express.favicon()
  app.use express.static(__dirname + "/../public")
  app.use express.logger()
  app.use express.cookieParser()
  app.use express.bodyParser()
  app.use app.router
  app.set 'port', port
  app.set 'host', host
  app.use express.logger(format: "\u001b[1m:method\u001b[0m \u001b[33m:         url\u001b[0m :response-time ms")
  app.use express.session
    store: new MemStore
      reapInterval: 60000 * 10
    secret:"atffl75$%R"
  app.set "mailOptions",
    host: mailhost
    port: mailport
    from: mailfrom

app.configure "development", ->
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )


authenticateFromLoginToken = (req, res, next) ->
  cookie = JSON.parse(req.cookies.logintoken)
  LoginToken.findOne
    email: cookie.email
    series: cookie.series
    token: cookie.token
  , ((err, token) ->
    unless token
      res.redirect "/sessions/new"
      return
    User.findOne
      email: token.email
    , (err, user) ->
      if user
        req.currentUser = user
        token.token = token.randomToken()
        token.save ->
          res.cookie "logintoken", token.cookieValue,
            expires: new Date(Date.now() + 2 * 604800000)
            path: "/"
          next()
      else
        res.redirect "/sessions/new"

  )

loadUser = (req, res, next) ->
  if req.cookies.logintoken
    authenticateFromLoginToken req, res, next
  else
    res.redirect "/sessions/new"

# Routes
app.get "/", loadUser, (req, res, next) ->
  routes.index req, res, next
app.post "/create", loadUser, (req, res, next) ->
  routes.create req, res, next
app.get "/destroy/:id", loadUser, (req, res, next) ->
  routes.destroy req, res, next
app.get "/edit/:id", loadUser, (req, res, next) ->
  routes.edit req, res, next
app.post "/update/:id", loadUser, (req, res, next) ->
  routes.update req, res, next
app.get "/users/new", (req, res, next) ->
  if (req.cookies.logintoken)
    cookie = JSON.parse(req.cookies.logintoken)
    LoginToken.findOne
      email: cookie.email
      series: cookie.series
      token: cookie.token
    , ((err, token) ->
      return routes.user req, res, next if !token
      User.findOne
        email: token.email
      , (err, user) ->
        if user
          req.currentUser = user
          token.token = token.randomToken()
          token.save ->
            res.cookie "logintoken", token.cookieValue,
              expires: new Date(Date.now() + 2 * 604800000)
              path: "/"
            return res.redirect "/"
        else
          routes.user req, res, next
    )
  else
    routes.user req, res, next

app.post "/users.:format?", (req, res, next) ->
  user = new User(req.body.user)
  user.save (err) ->
    if err
      return res.redirect "/users/new"
    emails.sendWelcome user
    switch req.params.format
      when "json"
        res.send user.toObject()
      else
        res.redirect "/"

app.get "/sessions/new", (req, res, next) ->
  if (req.cookies.logintoken)
    cookie = JSON.parse(req.cookies.logintoken)
    LoginToken.findOne
      email: cookie.email
      series: cookie.series
      token: cookie.token
    , ((err, token) ->
      return routes.session req, res, next if !token
      User.findOne
        email: token.email
      , (err, user) ->
        if user
          req.currentUser = user
          token.token = token.randomToken()
          token.save ->
            res.cookie "logintoken", token.cookieValue,
              expires: new Date(Date.now() + 2 * 604800000)
              path: "/"
            return res.redirect "/"
        else
          routes.session req, res, next
    )
  else
    routes.session req, res, next

app.post "/sessions", (req, res, next) ->
  User.findOne
    email: req.body.user.email
  , (err, user) ->
    if user and user.authenticate(req.body.user.password)
      expire = new Date(Date.now() + 2 * 604800000)
      loginToken = new LoginToken()
      loginToken.email = user.email
      loginToken.save ->
        res.cookie "logintoken", loginToken.cookieValue,
          expires: expire
          path: "/"
        console.info "cookie: ",loginToken.cookieValue
        res.redirect "/"
    else
      res.redirect "/sessions/new"

app.get "/sessions", loadUser, (req, res, next) ->
  LoginToken.remove
    email: req.cookie.email
    series: req.cookie.series
    token: req.cookie.token
    , ->

  res.clearCookie "logintoken"
  res.redirect "/sessions/new"

app.del "/sessions", loadUser, (req, res, next) ->
  LoginToken.remove
    email: req.currentUser.email
    , ->
  res.clearCookie "logintoken"
  res.redirect "/sessions/new"

unless module.parent
  app.listen port, host, (err) ->
    if err
      console.error 'failed to start server on %s:%s with error: %s', host, port, err
      process.exit -1
    console.info 'started server on %s:%s', host, port
    console.info 'environment: %s', app.settings.env

