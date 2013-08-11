http = require 'http'
fs = require 'fs'
path = require 'path'

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

server.listen 4000
