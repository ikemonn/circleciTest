# myModule.js

exports.greet = (name) ->
  return "Hello,"+ name


exports.greetAsync = (name, callback) ->
  greet = "Hello,"+ name
  callback greet
