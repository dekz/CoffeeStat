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

client ->
  window.onload = ->
    console.log 'loaded'
    getAnchors = (p1x, p1y, p2x, p2y, p3x, p3y) ->
      l1 = (p2x - p1x) / 2
      l2 = (p3x - p2x) / 2
      a = Math.atan((p2x - p1x) / Math.abs(p2y - p1y))
      b = Math.atan((p3x - p2x) / Math.abs(p2y - p3y))
      a = if p1y < p2y then Math.PI - a else a
      b = if p3y < p2y then Math.PI - b else b
      alpha = Math.PI / 2 - ((a + b) % (Math.PI * 2)) / 2
      dx1 = l1 * Math.sin(alpha + a)
      dy1 = l1 * Math.cos(alpha + a)
      dx2 = l2 * Math.sin(alpha + b)
      dy2 = l2 * Math.cos(alpha + b)
      return {
        x1: p2x - dx1,
        y1: p2y + dy1,
        x2: p2x + dx2,
        y2: p2y + dy2
    }
    
    labels = []
    data = []
    $("#data tfoot th").each(->
      labels.push($(this).html()))
    $("#data tbody td").each(->
      data.push($(this).html()))
    console.log data  
    width = 800
    height = 250
    leftgutter = 30
    bottomgutter = 20
    topgutter = 20
    colorhue = .6 || Math.random()
    color = "hsb(" + [colorhue, .5, 1] + ")"
    r = Raphael("holder", width, height)
    txt = {font: '12px Helvetica, Arial', fill: "#fff"}
    txt1 = {font: '10px Helvetica, Arial', fill: "#fff"}
    txt2 = {font: '12px Helvetica, Arial', fill: "#000"}
    X = (width - leftgutter) / labels.length
    max = Math.max.apply(Math, data)
    Y = (height - bottomgutter - topgutter) / max
    r.drawGrid(leftgutter + X * .5 + .5, topgutter + .5, width - leftgutter - X, height - topgutter - bottomgutter, 10, 10, "#333")
    
    path = r.path().attr({stroke: color, "stroke-width": 4, "stroke-linejoin": "round"})
    bgp = r.path().attr({stroke: "none", opacity: .3, fill: color})
    label = r.set()
    is_label_visible = false
    leave_timer = 0
    blanket = r.set()
    label.push(r.text(60, 12, "24 hits").attr(txt))
    label.push(r.text(60, 27, "22 September 2008").attr(txt1).attr({fill: color}))
    label.hide()
    
    frame = r.popup(100, 100, label, "right").attr({fill: "#000", stroke: "#666", "stroke-width": 2, "fill-opacity": .7}).hide()
    ii = labels.length
    p = []
    bgpp = []
    for i in [0..ii]
      y = Math.round(height - bottomgutter - Y * data[i])
      x = Math.round(leftgutter + X * (i + .5))
      t = r.text(x, height - 6, labels[i]).attr(txt).toBack()
      if i is 0
        p = ["M", x, y, "C", x, y]
        bgpp = ["M", leftgutter + X * .5, height - bottomgutter, "L", x, y, "C", x, y]
      if i and i < ii-1
        Y0 = Math.round(height - bottomgutter - Y * data[i - 1])
        X0 = Math.round(leftgutter + X * (i - .5))
        Y2 = Math.round(height - bottomgutter - Y * data[i + 1])
        X2 = Math.round(leftgutter + X * (i + 1.5))
        a = getAnchors(X0, Y0, x, y, X2, Y2)
        p = p.concat([a.x1, a.y1, x, y, a.x2, a.y2])
        bgpp = bgpp.concat([a.x1, a.y1, x, y, a.x2, a.y2])
      dot = r.circle(x, y, 4).attr({fill: "#000", stroke: color, "stroke-width": 2})
      blanket.push(r.rect(leftgutter + X * i, 0, X, height - bottomgutter).attr({stroke: "none", fill: "#fff", opacity: 0}))
      rect = blanket[blanket.length - 1]
      ((x, y, data, lbl, dot) ->
        i = 0
        timer = 0
        rect.hover(->
          clearTimeout(leave_timer)
          side = "right"
          if (x + frame.getBBox().width > width)
            side = "left"
          ppp = r.popup(x, y, label, side, 1)
          frame.show().stop().animate({path: ppp.path}, 200 * is_label_visible)
          label[0].attr({text: data + " hit" + ( if data is 1 then "" else "s")}).show().stop().animateWith(frame, {translation: [ppp.dx, ppp.dy]}, 200 * is_label_visible)
          label[1].attr({text: lbl + " September 2008"}).show().stop().animateWith(frame, {translation: [ppp.dx, ppp.dy]}, 200 * is_label_visible)
          dot.attr("r", 6)
          is_label_visible = true
        ->
          dot.attr("r", 4)
          leave_timer = setTimeout(->
            frame.hide();
            label[0].hide();
            label[1].hide();
            is_label_visible = false;
          , 1)
        )
      )(x, y, data[i], labels[i], dot)
    # x = 10
    # y = 10
    # p = p.concat([x,y,x,y])
    # bgpp = bgpp.concat([x, y, x, y, "L", x, height - bottomgutter, "z"])
    # path.attr({path: p})
    # bgp.attr({path: bgpp})
    frame.toFront()
    label[0].toFront()
    label[1].toFront()
    blanket.toFront()

  $(document).ready ->
    socket = new io.Socket()

    socket.on 'connect', -> $('#log').append '<p>Connected</p>'
    socket.on 'disconnect', -> $('#log').append '<p>Disconnected</p>'
    socket.on 'message', (raw_msg) ->
      msg = JSON.parse raw_msg
      if msg.connected then $('#log').append "<p>#{msg.connected.id} Connected</p>"
      else if msg.said then $('#log').append "<p>#{msg.said.id}: #{msg.said.text}</p>"
      else if msg.networkStream then console.log msg.networkStream

    $('form').submit ->
      socket.send JSON.stringify said: {text: $('#box').val()}
      $('#box').val('').focus()
      false

    socket.connect()
    $('#box').focus()
    
    Raphael.fn.drawGrid = (x, y, w, h, wv, hv, color) ->
      color = color || "#000"
      path = ["M", Math.round(x) + .5, Math.round(y) + .5, "L", Math.round(x + w) + .5, Math.round(y) + .5, Math.round(x + w) + .5, Math.round(y + h) + .5, Math.round(x) + .5, Math.round(y + h) + .5, Math.round(x) + .5, Math.round(y) + .5]
      rowHeight = h / hv
      columnWidth = w / wv
      for i in [1..hv]
        path = path.concat(["M", Math.round(x + i * columnWidth) + .5, Math.round(y) + .5, "V", Math.round(y + h) + .5])
      return this.path(path.join(",")).attr({stroke: color})
    
  

view ->
  @title = 'CoffeeStat'
  @scripts = ['http://code.jquery.com/jquery-1.4.3.min', '/socket.io/socket.io', '/default', 'http://github.com/DmitryBaranovskiy/raphael/raw/master/raphael-min', 'raphael/popup']

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