client ->
  chart = null
  refresh = ->
    setInterval(->
      $.ajax
        url: '/'
        success: -> document.location = document.location
    , 1000)
  
  $(document).ready ->
    socket = new io.Socket()

    socket.on 'connect', ->
      $('#log').append '<p>Connected</p>'
      
    socket.on 'disconnect', ->
      $('#log').append '<p>Disconnected</p>'
      refresh()
    
    socket.on 'message', (raw_msg) ->
      msg = JSON.parse raw_msg
      if msg.connected then $('#log').append "<p>#{msg.connected.id} Connected</p>"
      else if msg.said then $('#log').append "<p>#{msg.said.id}: #{msg.said.text}</p>"
      else if msg.network
        # console.log msg
        x =  (new Date()).getTime()
        rx_y = msg.network.rx
        tx_y = msg.network.tx
        chart.series[0].addPoint [x, rx_y], false, true, false
        chart.series[1].addPoint [x, tx_y], false, true, false
        chart.redraw()

    $('form').submit ->
      socket.send JSON.stringify said: {text: $('#box').val()}
      $('#box').val('').focus()
      false

    socket.connect()
    $('#box').focus()
  
  `
  $(document).ready(function() {
     console.log('ready');
     chart = new Highcharts.Chart({
        chart: {
           renderTo: 'container',
           defaultSeriesType: 'spline',
           marginRight: 10,
           events: {
              load: function() {
                 //
                 //// set up the updating of the chart each second
                 //var series = this.series[0];
                 //setInterval(function() {
                 //   var x = (new Date()).getTime(), // current time
                 //      y = Math.random();
                 //   series.addPoint([x, y], true, true);
                 //}, 1000);
              }
           }
        },
        title: {
           text: 'Rx/Tx vs Time'
        },
        xAxis: {
           type: 'datetime',
           tickPixelInterval: 150
        },
        yAxis: {
           title: {
              text: 'kbit/s'
           },
           plotLines: [{
              value: 0,
              width: 1,
              color: '#808080'
           }],
           min: 0
        },
        tooltip: {
           formatter: function() {
                     return '<b>'+ this.series.name +'</b><br/>'+
                 Highcharts.dateFormat('%Y-%m-%d %H:%M:%S', this.x) +'<br/>'+ 
                 Highcharts.numberFormat(this.y, 2);
           }
        },
        legend: {
           enabled: true
        },
        exporting: {
           enabled: false
        },
        series: [{
           name: 'Rx',
           data: (function() {
              // generate an array of random data
              var data = [],
                 time = (new Date()).getTime(),
                 i;
              for (i = -19; i <= 0; i++) {
                 data.push({
                    x: time + i * 1000,
                    y: Math.random() * 10
                 });
              }
              return data;
           })()
           // data: [{x: (new Date()).getTime() + 1000, y: 1}, {x: (new Date()).getTime() + 2000, y: 2}]
        },
        {
           name: 'Tx',
           data: (function() {
              // generate an array of random data
              var data = [],
                 time = (new Date()).getTime(),
                 i;
              for (i = -19; i <= 0; i++) {
                 data.push({
                    x: time + i * 1000,
                    y: Math.random() * 10
                 });
              }
              return data;
           })()
           // data: [{x: (new Date()).getTime() + 1000, y: 1}, {x: (new Date()).getTime() + 2000, y: 2}]
        }]
     });
  });
  `
  true