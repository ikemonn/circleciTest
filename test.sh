#!/bin/sh
# mocha --compilers coffee:coffee-script/register test.coffee
node_modules/mocha/bin/mocha --compilers coffee:coffee-script/register test.coffee
# echo $?
if [ $? -eq 1 ]; then
  echo "とおた"
  node_modules/mocha/bin/mocha --compilers coffee:coffee-script/register test.coffee
  exit 0
else
  echo "とおてない"
fi
