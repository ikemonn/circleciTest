assert = require('assert')
myModule = require('./myModule.coffee')

describe 'greet', ->
  it '足し算', ->
    console.log new Date()
    assert.equal(1, 2)
  it '引数に応じて決まった文字列を返すこと', ->
    console.log "hoge"
    assert.equal(myModule.greet('taro'), 'Hello,taro')
