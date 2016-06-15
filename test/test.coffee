Helper = require("hubot-test-helper")
expect = require("chai").expect
proxyquire = require("proxyquire")

nodeGeocoderStub = () ->
  geocode: () ->
    return new Promise (resolve, reject) ->
      resolve([{latitude: -33.4666204, longitude: -70.62697539999999}])
geoWhat3wordsStub = (apiKey, options) ->
  reverse: (params) ->
    return new Promise (resolve, reject) ->
      resolve("presume.wiggly.crimson")
  getLanguages: () ->
    return new Promise (resolve, reject) ->
      resolve(["ru", "sv", "pt", "sw", "en", "it", "fr", "es", "tr"])
proxyquire("./../src/script.coffee", {
  "node-geocoder": nodeGeocoderStub,
  "geo.what3words": geoWhat3wordsStub
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
      room.user.say("user", "hubot w3w addr vicuña mackena 1751 santiago")
      setTimeout(done, 100)

    it "should get a w3w", ->
      expect(room.messages).to.eql([
        ["user", "hubot w3w addr vicuña mackena 1751 santiago"]
        ["hubot", "presume.wiggly.crimson"]
      ])

  context "get w3w from coordinates", ->
    beforeEach (done) ->
      room.user.say("user", "hubot w3w coords -33.4666204,-70.62697539999999")
      setTimeout(done, 100)

    it "should get a w3w", ->
      expect(room.messages).to.eql([
        ["user", "hubot w3w coords -33.4666204,-70.62697539999999"]
        ["hubot", "presume.wiggly.crimson"]
      ])

  context "set lang", ->
    beforeEach (done) ->
      room.user.say("user", "hubot w3w lang es")
      setTimeout(done, 100)

    it "should set a lang", ->
      expect(room.messages).to.eql([
        ["user", "hubot w3w lang es"]
        ["hubot", "Language set at \"Spanish\""]
      ])
