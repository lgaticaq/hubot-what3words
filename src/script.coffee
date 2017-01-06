# Description
#   A hubot script to get what3words from a address or coordinates
#
# Dependencies:
#   "geo.what3words": "^2.0.0",
#   "iso-639-1": "^1.2.1",
#   "node-geocoder": "^3.15.1"
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
  getLang = () ->
    lang = robot.brain.get("w3w:lang") or process.env.W3W_LANG or "en"
    return if iso6391.validate(lang) then lang else "en"

  robot.respond /w3w addr ([\w\W]+)/, (res) ->
    address = res.match[1]
    geocoder = NodeGeocoder({provider: "google"})
    geocoder.geocode(address).then (results) ->
      coords = "#{results[0].latitude},#{results[0].longitude}"
      lang = getLang()
      w3w = new What3Words(process.env.W3W_API_KEY, {language: lang})
      return w3w.reverse({coords: coords, lang: lang})
    .then (response) ->
      res.send response
    .catch (err) ->
      res.reply err.message or "an error occurred"
      robot.emit "error", err

  robot.respond /w3w coords (-?\d+\.\d+),(-?\d+\.\d+)/, (res) ->
    latitude = res.match[1]
    longitude = res.match[2]
    lang = getLang()
    try
      w3w = new What3Words(process.env.W3W_API_KEY, {language: lang})
      geocoder = NodeGeocoder({provider: "google"})
      promises = [
        w3w.reverse({coords: "#{latitude},#{longitude}", lang: lang})
        geocoder.reverse({lat: latitude, lon: longitude})
      ]
      Promise.all(promises)
      .then (results) ->
        address = results[1][0].formattedAddress
        res.send "w3w: #{results[0]}\naddress: #{address}"
      .catch (err) ->
        res.reply err.message or "an error occurred"
        robot.emit "error", err
    catch err
      res.reply err.message
      robot.emit "error", err

  robot.respond /w3w lang (\w{2})/i, (res) ->
    lang = res.match[1].trim()
    unless iso6391.validate(lang)
      return res.reply "#{lang} is not a valid ISO-639-1 language"
    try
      w3w = new What3Words(process.env.W3W_API_KEY, {language: getLang()})
      w3w.getLanguages({}).then (languages) ->
        unless lang in languages
          msg = "#{lang} is not available. Only #{languages.join(", ")}"
          return res.reply msg
        robot.brain.set("w3w:lang", lang)
        res.send "Language set at \"#{iso6391.getName(lang)}\""
    catch err
      res.reply err.message
      robot.emit "error", err
