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
  
msg networkStream: ->
  console.log "received stream data"
  console.log "#{id} said: #{@text}"
  send 'said', id: id, text: @text
  broadcast 'said', id: id, text: @text

include 'client.coffee'

view ->
  @title = 'CoffeeStat'
  @scripts = ['http://code.jquery.com/jquery-1.4.3.min', '/socket.io/socket.io', '/default', 'http://github.com/DmitryBaranovskiy/raphael/raw/master/raphael-min', 'raphael/popup']
  style '''
      body {
        background: #000;
      }
      #holder {
        height: 250px;
        width: 800px;
      }
  '''
  h1 @title
  div id: 'log'
  form ->
    input id: 'box'
    button id: 'say', -> 'Say'
  table id: 'data', ->
    tfoot ->
      tr ->
        th i for i in [1..31]
    tbody ->
      tr ->
        td i for i in [1..31]
  div id: 'holder'
          
    
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
    registry.send 'networkStream', id: 0, text: JSON.stringify(streamData)



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