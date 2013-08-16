http = require 'http'
fs = require 'fs'
path = require 'path'
coffee = require 'coffee-script'

notFound = (response) ->
  response.statusCode = 404
  response.write 'Not found\n'
  response.end()

server = http.createServer (request, response) ->
  extension = path.extname request.url
  request_path = request.url
  request_path = '/index.html' if request_path == '/'
  file = "#{__dirname}#{request_path}"
  fs.stat file, (err, info) ->
    if err
      if extension == '.js'
        coffee_file = file.replace /\.js$/, '.coffee'
        fs.stat coffee_file, (err, info) ->
          if err
            notFound response
          else
            fs.readFile coffee_file, 'utf8', (err, content) ->
              throw err if err
              fs.writeFile file, coffee.compile(content), (err) ->
                throw err if err
      else
        notFound response
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
