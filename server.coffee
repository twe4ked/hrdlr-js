http = require 'http'
fs = require 'fs'
path = require 'path'
coffee = require 'coffee-script'

notFound = (response) ->
  response.statusCode = 404
  response.write 'Not found\n'
  response.end()

setContentTypeHeader = (response, extension) ->
  extension = '.html' if extension == ''
  type = {
    '.html': 'text/html',
    '.js': 'text/javascript',
    '.m4a': 'audio/mp4',
  }[extension]
  response.setHeader 'Content-Type', type || 'text/plain'

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
              js_content = coffee.compile(content)
              response.write js_content
              response.end()
              fs.writeFile file, js_content
      else
        notFound response
    else
      setContentTypeHeader response, extension
      if extension == '.m4a'
        response.setHeader 'Accept-Ranges', 'bytes'
      response.setHeader 'Content-Length', info.size
      fs.createReadStream(file).pipe response

io = require('socket.io').listen(server)
io.configure ->
  io.set 'transports', ['xhr-polling']
  io.set 'polling duration', 10
io.sockets.on 'connection', (socket) ->
  socket.on 'message', (data) ->
    io.sockets.send data

port = process.env.PORT || 4000
server.listen port
