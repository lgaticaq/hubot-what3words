Helper = require("hubot-test-helper")
expect = require("chai").expect
proxyquire = require("proxyquire")

nodeGeocoderStub = () ->
  geocode: (address) ->
    return new Promise (resolve, reject) ->
      if address is "street 1"
        reject(new Error("Not found"))
      else
        resolve([{latitude: -33.4666204, longitude: -70.62697539999999}])
class What3wordsStub
  constructor: (apiKey, options) ->
    if typeof apiKey is "undefined"
      throw new Error("Not api key")
    else
      return {reverse: @reverse, getLanguages: @getLanguages}
  reverse: (params) ->
    return new Promise (resolve, reject) ->
      if params.coords is "1.1,1.1"
        reject(new Error("Not found"))
      else
        resolve("presume.wiggly.crimson")
  getLanguages: () ->
    return new Promise (resolve, reject) ->
      resolve(["ru", "sv", "pt", "sw", "en", "it", "fr", "es", "tr"])
proxyquire("./../src/script.coffee", {
  "node-geocoder": nodeGeocoderStub,
  "geo.what3words": What3wordsStub
})

helper = new Helper("./../src/index.coffee")

describe "hubot-what3words", ->
  room = null

  beforeEach ->
    room = helper.createRoom()

  afterEach ->
    room.destroy()

  context "get w3w from address", ->
    beforeEach (done) ->
      process.env.W3W_API_KEY = "0123456789"
      room.user.say("user", "hubot w3w addr vicuña mackena 1751 santiago")
      setTimeout(done, 100)

    it "should get a w3w", ->
      expect(room.messages).to.eql([
        ["user", "hubot w3w addr vicuña mackena 1751 santiago"]
        ["hubot", "presume.wiggly.crimson"]
      ])

  context "get w3w from coordinates", ->
    beforeEach (done) ->
      process.env.W3W_API_KEY = "0123456789"
      room.user.say("user", "hubot w3w coords -33.4666204,-70.62697539999999")
      setTimeout(done, 100)

    it "should get a w3w", ->
      expect(room.messages).to.eql([
        ["user", "hubot w3w coords -33.4666204,-70.62697539999999"]
        ["hubot", "presume.wiggly.crimson"]
      ])

  context "set lang", ->
    beforeEach (done) ->
      process.env.W3W_API_KEY = "0123456789"
      process.env.W3W_LANG = "asdf"
      room.user.say("user", "hubot w3w lang es")
      setTimeout(done, 100)

    it "should set a lang", ->
      expect(room.messages).to.eql([
        ["user", "hubot w3w lang es"]
        ["hubot", "Language set at \"Spanish\""]
      ])

  context "get w3w from coordinates with error", ->
    beforeEach (done) ->
      process.env.W3W_API_KEY = "0123456789"
      room.user.say("user", "hubot w3w coords 1.1,1.1")
      setTimeout(done, 100)

    it "should get a w3w", ->
      expect(room.messages).to.eql([
        ["user", "hubot w3w coords 1.1,1.1"]
        ["hubot", "@user Not found"]
      ])

  context "get w3w from coordinates with error", ->
    beforeEach (done) ->
      delete process.env.W3W_API_KEY
      room.user.say("user", "hubot w3w coords 1.1,1.1")
      setTimeout(done, 100)

    it "should get a w3w", ->
      expect(room.messages).to.eql([
        ["user", "hubot w3w coords 1.1,1.1"]
        ["hubot", "@user Not api key"]
      ])

  context "get w3w from address with error", ->
    beforeEach (done) ->
      delete process.env.W3W_API_KEY
      room.user.say("user", "hubot w3w addr street 1")
      setTimeout(done, 100)

    it "should get a w3w", ->
      expect(room.messages).to.eql([
        ["user", "hubot w3w addr street 1"]
        ["hubot", "@user Not found"]
      ])

  context "set invalid lang", ->
    beforeEach (done) ->
      process.env.W3W_API_KEY = "0123456789"
      delete process.env.W3W_LANG
      room.user.say("user", "hubot w3w lang xx")
      setTimeout(done, 100)

    it "should set a lang", ->
      expect(room.messages).to.eql([
        ["user", "hubot w3w lang xx"]
        ["hubot", "@user xx is not a valid ISO-639-1 language"]
      ])

  context "set not available lang", ->
    beforeEach (done) ->
      process.env.W3W_API_KEY = "0123456789"
      delete process.env.W3W_LANG
      room.user.say("user", "hubot w3w lang as")
      setTimeout(done, 100)

    it "should set a lang", ->
      availables = "ru, sv, pt, sw, en, it, fr, es, tr"
      expect(room.messages).to.eql([
        ["user", "hubot w3w lang as"]
        ["hubot", "@user as is not available. Only #{availables}"]
      ])

  context "set lang with error", ->
    beforeEach (done) ->
      delete process.env.W3W_API_KEY
      delete process.env.W3W_LANG
      room.user.say("user", "hubot w3w lang as")
      setTimeout(done, 100)

    it "should set a lang", ->
      availables = "ru, sv, pt, sw, en, it, fr, es, tr"
      expect(room.messages).to.eql([
        ["user", "hubot w3w lang as"]
        ["hubot", "@user Not api key"]
      ])
