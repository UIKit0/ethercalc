@include = ->
  json = try require('fs').readFileSync('/home/dotcloud/environment.json', 'utf8')

  unless json?
    io.configure ->
      io.set "transports", ['server-events', 'flashsocket', 'htmlfile', 'xhr-multipart', 'xhr-polling']
      io.set "polling duration", 10
    return

  env = process.env

  { DOTCLOUD_DATA_REDIS_HOST: env.REDIS_HOST
  , DOTCLOUD_DATA_REDIS_PORT: env.REDIS_PORT
  , DOTCLOUD_DATA_REDIS_PASSWORD: env.REDIS_PASS
  } = JSON.parse(json)

  io.configure ->
    io.set "transports", ["xhr-polling"]
    io.set "polling duration", 10

    path = require('path')
    HTTPPolling = require(path.join(path.dirname(require.resolve('socket.io')), 'lib', 'transports', 'http-polling'))
    XHRPolling  = require(path.join(path.dirname(require.resolve('socket.io')), 'lib', 'transports', 'xhr-polling'))
    XHRPolling.prototype.doWrite = (data) ->
      HTTPPolling.prototype.doWrite.call(@)

      origin = @req.headers.origin
      headers =
        'Content-Type': 'text/plain; charset=UTF-8'
        'Content-Length': if data is undefined then 0 else Buffer.byteLength(data)
        
      if origin
        # https://developer.mozilla.org/En/HTTP_Access_Control
        headers['Access-Control-Allow-Origin'] = '*'
        headers['Access-Control-Allow-Credentials'] = 'true' if @req.headers.cookie
        
      @response.writeHead 200, headers
      @response.write data
      # @log.debug this.name + ' writing', data
