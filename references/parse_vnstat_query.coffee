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