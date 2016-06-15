# Description
#   A hubot script to get what3words from a address or coordinates
#
# Dependencies:
#   "geo.what3words": "^2.0.0",
#   "iso-639-1": "^1.2.1",
#   "node-geocoder": "^3.11.0"
#
# Configuration:
#   W3W_API_KEY
#   W3W_LANG
#
# Commands:
#   hubot w3w addr <address> - Get w3w from address
#   hubot w3w coords <lat>,<lng> - Get w3w from coordinates
#   hubot w3w lang <lang> - Set language
#
# Author:
#   lgaticaq

NodeGeocoder = require("node-geocoder")
What3Words = require("geo.what3words")
iso6391 = require("iso-639-1")

module.exports = (robot) ->

  LANG = robot.brain.get("w3w:lang") or process.env.W3W_LANG or "en"
  LANG = if iso6391.validate(LANG) then LANG else "en"

  w3w = new What3Words(process.env.W3W_API_KEY, {language: LANG})
  geocoder = NodeGeocoder({provider: "google"})

  robot.respond /w3w addr ([\w\W]+)/, (res) ->
    address = res.match[1]
    geocoder.geocode(address).then (results) ->
      coords = "#{results[0].latitude},#{results[0].longitude}"
      return w3w.reverse({coords: coords, lang: LANG})
    .then (response) ->
      res.send response
    .catch (err) ->
      res.reply "an error occurred"
      robot.emit "error", err

  robot.respond /w3w coords (-?\d+\.\d+),(-?\d+\.\d+)/, (res) ->
    latitude = res.match[1]
    longitude = res.match[2]
    w3w.reverse({coords: "#{latitude},#{longitude}", lang: LANG})
    .then (response) ->
      res.send response
    .catch (err) ->
      res.reply "an error occurred"
      robot.emit "error", err

  robot.respond /w3w lang (\w{2})/i, (res) ->
    lang = res.match[1].trim()
    unless iso6391.validate(lang)
      return res.reply "#{lang} is not a valid ISO-639-1 language"
    w3w.getLanguages({}).then (languages) ->
      unless lang in languages
        msg = "#{lang} is not available. Only #{languages.join(", ")}"
        return res.reply msg
      robot.brain.set("w3w:lang", lang)
      LANG = lang
      res.send "Language set at \"#{iso6391.getName(lang)}\""
