registry = {}
def registry: registry

get '/': -> render 'default'

get '/counter': -> "# of messages so far: #{app.counter}"

at connection: ->
  app.counter ?= 0
  console.log "Connected: #{id}"
  broadcast 'connected', id: id
  
  registry.send = send

at disconnection: ->
  console.log "Disconnected: #{id}"

msg said: ->
  console.log "#{id} said: #{@text}"
  app.counter++
  send 'said', id: id, text: @text
  broadcast 'said', id: id, text: @text

client ->
  $(document).ready ->
    socket = new io.Socket()

    socket.on 'connect', -> $('#log').append '<p>Connected</p>'
    socket.on 'disconnect', -> $('#log').append '<p>Disconnected</p>'
    socket.on 'message', (raw_msg) ->
      msg = JSON.parse raw_msg
      if msg.connected then $('#log').append "<p>#{msg.connected.id} Connected</p>"
      else if msg.said then $('#log').append "<p>#{msg.said.id}: #{msg.said.text}</p>"

    $('form').submit ->
      socket.send JSON.stringify said: {text: $('#box').val()}
      $('#box').val('').focus()
      false

    socket.connect()
    $('#box').focus()

view ->
  @title = 'Nano Chat'
  @scripts = ['http://code.jquery.com/jquery-1.4.3.min', '/socket.io/socket.io', '/default']

  h1 @title
  div id: 'log'
  form ->
    input id: 'box'
    button id: 'say', -> 'Say'
    
    
## Here be data dragons

stdin = process.openStdin()
sys = require 'utils'
spawn = require('child_process').spawn
  
analyzeData = (data) ->
  console.log 'analysing data'
  data = data.split '\n'
  day = new Array()
  hour = new Array()
  month = new Array()
  top = new Array()
  summary = new Array()
  for line in data
    # sys.puts sys.inspect line
    # sys.puts '------------'
    item = line.split ';'
    # sys.puts sys.inspect item
    # sys.puts '------------'
    switch item[0]
      when 'd' 
        day[item[1]] = {}
        day[item[1]].time = item[2]
        day[item[1]].rx   = item[3] * 1024 + item[5]
        day[item[1]].tx   = item[4] * 1024 + item[6]
        day[item[1]].act  = item[7]
        break
      when 'm'
        month[item[1]] = {}
        month[item[1]].time = item[2]
        month[item[1]].rx   = item[3] * 1024 + item[5]
        month[item[1]].tx   = item[4] * 1024 + item[6]
        month[item[1]].act  = item[7]
        break
      when 'h'
        hour[item[1]] = {}
        hour[item[1]].time = item[2]
        hour[item[1]].rx   = item[3] * 1024 + item[5]
        hour[item[1]].tx   = item[4] * 1024 + item[6]
        hour[item[1]].act  = item[7]
        break
      when 't'
        top[item[1]] = {}
        top[item[1]].time = item[2]
        top[item[1]].rx   = item[3] * 1024 + item[5]
        top[item[1]].tx   = item[4] * 1024 + item[6]
        top[item[1]].act  = item[7]
        break
      else
        summary[item[0]] = {}
        summary[item[0]].info = item[1]

  sys.puts sys.inspect summary
  
  
parseStreamData = (streamData) ->
  sys.puts streamData
  
  if registry.send
    registry.send 'said', id: 0, text: JSON.stringify(streamData)
    # broadcast 'stream', rx: streamData[1], tx: streamData[4], time: new Date()


watchNetworkStats = (interface) ->
  stats = spawn 'vnstat', ['-i', interface, '-l']
  statsData = ''

  stats.stdout.on 'data', (data) ->
    data = '' + data
    clean = data.replace(/\s{2,}/g,';')
    test = clean.split(';')
    parseStreamData test.slice(1)

    stats.stderr.on 'data', (data) ->
      sys.print 'stderr: ' + data

    stats.on 'exit', (code) ->
      console.log 'child process exited with code ' + code

init = ->
  #stats = spawn 'vnstat', ['--dumpdb', '-i', 'en1'] 
  watchNetworkStats 'en1'

init()