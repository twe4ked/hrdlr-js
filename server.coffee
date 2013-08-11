http = require 'http'
fs = require 'fs'
path = require 'path'
websocketss = require 'websocketss'

server = http.createServer (request, response) ->
  path = request.url
  path = '/index.html' if path == '/'
  file = "#{__dirname}#{path}"
  fs.stat file, (err, info) ->
    if err
      response.statusCode = 404
      response.write 'Not found\n'
      response.end()
    else
      response.setHeader 'Accept-Ranges', 'bytes'
      response.setHeader 'Content-Length', info.size
      fs.createReadStream(file).pipe response

wss = new websocketss.Server
wss.on 'message', (message, wssocket) ->
  wss.broadcast message
wss.listen server

server.listen 4000
