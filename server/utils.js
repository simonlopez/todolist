// Generated by CoffeeScript 1.4.0
var conf, confKey, fs, pathUtil, type, yaml;

yaml = require('js-yaml');

fs = require('fs');

pathUtil = require('path');

conf = null;

confKey = function(key, def) {
  var confPath, i, last, obj, path, step, _i, _len;
  if (conf === null) {
    confPath = pathUtil.resolve("" + (process.cwd()) + "/conf/" + (process.env.NODE_ENV ? process.env.NODE_ENV : 'dev') + "-conf.yml");
    try {
      conf = yaml.load(fs.readFileSync(confPath, 'utf8'));
    } catch (err) {
      throw new Error("Cannot read or parse configuration file '" + confPath + "': " + err);
    }
  }
  path = key.split('.');
  obj = conf;
  last = path.length - 1;
  for (i = _i = 0, _len = path.length; _i < _len; i = ++_i) {
    step = path[i];
    if (!(step in obj)) {
      if (def === void 0) {
        throw new Error("The " + key + " key is not defined in the configuration file");
      }
      return def;
    }
    if (i !== last) {
      obj = obj[step];
    } else {
      return obj[step];
    }
  }
};

type = function(obj) {
  return Object.prototype.toString.call(obj).slice(8, -1).toLowerCase();
};

module.exports = {
  type: type,
  confKey: confKey
};
