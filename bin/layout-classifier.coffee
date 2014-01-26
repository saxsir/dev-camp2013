#! /usr/bin/env node_modules/coffee-script/bin/coffee
error = (message)->
  console.error message
  process.exit()

args = process.argv
error '[Error] $ ./bin/layout-classifier.coffee /path/to/config_file' if args.length < 3

path = require 'path'
LayoutClassifier = require '../src/LayoutClassifier'
configPath = path.resolve(args[2])
config = require path.resolve(args[2])
LayoutClassifier.run config