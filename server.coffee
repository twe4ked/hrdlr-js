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

io = require('socket.io').listen(server)
io.sockets.on 'connection', (socket) ->
  socket.on 'message', (data) ->
    io.sockets.send data

port = process.env.PORT || 4000
server.listen port
