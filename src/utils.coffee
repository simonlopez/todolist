yaml = require 'js-yaml'
fs = require 'fs'
pathUtil = require 'path'

conf = null

# Read a configuration key inside the YAML configuration file (utf-8 encoded).
# At first call, performs a synchronous disk access, because configuraiton is very likely to be read
# before any other operation. The configuration is then cached.
#
# The configuration file read is named 'xxx-conf.yaml', where xxx is the value of NODE_ENV (dev if not defined)
# and located in a "conf" folder under the execution root.
#
# @param key [String] the path to the requested key, splited with dots.
# @param def [Object] the default value, used if key not present.
# If undefined, and if the key is missing, an error is thrown.
# @return the expected key.
confKey = (key, def) ->
  if conf is null
    confPath = pathUtil.resolve "#{process.cwd()}/conf/#{if process.env.NODE_ENV then process.env.NODE_ENV else 'dev'}-conf.yml"
    try
      # Intended to be synchronized: we absolutely need to load configuration data before going further
      conf = yaml.load fs.readFileSync confPath, 'utf8'
    catch err
      throw new Error "Cannot read or parse configuration file '#{confPath}': #{err}"

  path = key.split '.'
  obj = conf
  last = path.length-1
  for step, i in path
    unless step of obj
      # missing key or step
      throw new Error "The #{key} key is not defined in the configuration file" if def is undefined
      return def
    unless i is last
      # goes deeper
      obj = obj[step]
    else
      # last step: returns value
      return obj[step]

# Working version of typeof operator. http://bonsaiden.github.com/JavaScript-Garden/#types.typeof
#
# @param obj [Object] tested object. Could be undefined or null
# @return name of the awaited type, lower-case
type = (obj)  ->
  return Object.prototype.toString.call(obj).slice(8, -1).toLowerCase()

module.exports =
  type: type
  confKey: confKey
