mongoose = require 'mongoose'
Todo     = mongoose.model 'Todo'
User     = mongoose.model 'User'
utils    = require("connect").utils
utils2   = require '../utils'

appName = utils2.confKey 'app.name'

exports.index = (req, res, next) ->
  user_id = (if req.cookies then req.cookies.user_id else `undefined`)
  #Todo.find({user_id: user_id}).sort("-updated_at").exec (err, todos) ->
  console.info 'search with id: %s', user_id
  Todo.find {user_id: user_id},(err, todos) ->
    if err
      console.info err
    return next(err)  if err
    res.render "index.ejs",
      title: appName
      todos: todos


exports.create = (req, res, next) ->
  user_id = (if req.cookies then req.cookies.user_id else `undefined`)
  console.info 'save with id: %s', user_id
  new Todo(
    user_id: user_id
    content: req.body.content
    updated_at: Date.now()
  ).save (err, todo, count) ->
    return next(err)  if err
    res.redirect "/"

exports.destroy = (req, res, next) ->
  Todo.findById req.params.id, (err, todo) ->
    user_id = (if req.cookies then req.cookies.user_id else `undefined`)
    return utils.forbidden(res)  if todo.user_id isnt req.cookies.user_id
    todo.remove (err, todo) ->
      return next(err)  if err
      res.redirect "/"

exports.edit = (req, res, next) ->
  user_id = (if req.cookies then req.cookies.user_id else `undefined`)
  Todo.find(user_id: user_id).sort("-updated_at").exec (err, todos) ->
    return next(err)  if err
    res.render "edit.ejs",
      title: "Express Todo Example"
      todos: todos
      current: req.params.id

exports.update = (req, res, next) ->
  Todo.findById req.params.id, (err, todo) ->
    user_id = (if req.cookies then req.cookies.user_id else `undefined`)
    return utils.forbidden(res)  if todo.user_id isnt user_id
    todo.content = req.body.content
    todo.updated_at = Date.now()
    todo.save (err, todo, count) ->
      return next(err)  if err
      res.redirect "/"

exports.session = (req, res, next) ->
  console.info 'routes.session'
  #user_id = (if req.cookies then req.cookies.user_id else `undefined`)
  res.render "login.ejs",
    title: appName,
  console.info 'routes.session'

  #User.findById(user_id).exec (err, todos) ->
  #  if err
  #    res.render "login",
  #      title: appName
  #  else
  #    res.redirect "/"

exports.user = (req, res, next) ->
  console.info 'routes.user'
  res.render "create.ejs",
    title: appName
  #user_id = (if req.cookies then req.cookies.user_id else `undefined`)
  #User.findById(user_id).exec (err, todos) ->
  #  if err
  #    res.render "create",
  #      title: appName
  #  else
  #    res.redirect "/"
