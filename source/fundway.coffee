transitionDelay = 500
maxInterval = 100

$ ->
  margin = 
    top: 20
    right: 20
    bottom: 30
    left: 50

  width = window.innerWidth - 40 - margin.left - margin.right
  height = 500 - margin.top - margin.bottom
  parseDate = d3.time.format("%Y-%m-%d").parse
  x = d3.time.scale().range([ 0, width ])
  y = d3.scale.linear().range([ height, 0 ])
  xAxis = d3.svg.axis().scale(x).orient("bottom")
  yAxis = d3.svg.axis().scale(y).orient("left")
  line = d3.svg.line().x((d) ->
    x d.date
  ).y((d) ->
    y d.value
  )

  window.svg = d3.select("#graph")
          .append("svg")
          .attr("width", width + margin.left + margin.right)
          .attr("height", height + margin.top + margin.bottom)
          .append("g")
          .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

  data = [
    ["Date", "$", "Repeats"],
    ["2013-07-19", 6000, ""],
    ["2013-07-19", -600, "every 1 month"],
    ["2013-07-19", 400, "every 2 months"],
  ]
  $("#table").handsontable
    data: data
    startRows: 10
    startCols: 3
    afterChange: (changes, source) ->
      if source == "edit"
        reparse()

  svg.append("g")
     .attr("class", "x axis")
     .attr("transform", "translate(0," + height + ")")
     .call xAxis
  svg.append("g")
     .attr("class", "y axis")
     .call(yAxis)
     .append("text")
     .attr("transform", "rotate(-90)")
     .attr("y", 6).attr("dy", ".71em")
     .style("text-anchor", "end")
     .text "Funds ($)"
  svg.append("path")
     .attr("class", "line")
     #.attr "d", line(data)

  window.updateData = (data) ->
    x.domain d3.extent(data, (d) -> d.date)
    y.domain d3.extent(data, (d) -> d.value)

    svg = d3.select("#graph").transition()

    svg.select(".line")
       .duration(transitionDelay)
       .attr("d", line(data));
    svg.select(".x.axis")
       .duration(transitionDelay)
       .call(xAxis);
    svg.select(".y.axis")
       .duration(transitionDelay)
       .call(yAxis);

  interval_from = (repeat_words) ->
    regex = /every (\d+) (days?|weeks?|months?|years?)/ig
    matches = regex.exec(repeat_words)
    return null if not matches?
    if matches.length == 3
      factor =
        switch matches[2].toLowerCase()
          when "day", "days" then 60 * 60 * 24
          when "week", "weeks" then 60 * 60 * 24 * 7
          when "month", "months" then 60 * 60 * 24 * 30
          when "year", "years" then 60 * 60 * 24 * 365
      factor * parseInt(matches[1])
    else
      null

  reparse = ->
    ht = $("#table").handsontable('getInstance')
    data = ht.getData()
    
    parsed = [[parseDate(row[0]), row[1], interval_from(row[2])] for row in data[1..]][0]
    points = []

    # Turn our set of repetitive events into static, concrete data points.
    for obj in parsed
      [date, value, interval] = obj
      if interval?
        for i in [0..maxInterval]
          points.push({
            date: new Date(date.getTime() + (i * interval * 1000)),
            value: value
          })
      else
        points.push({
          date: date,
          value: value
        })

    points.sort (a, b) -> a.date.getTime() - b.date.getTime()

    epoints = []
    # Convert to running totals
    value = 0.0
    for obj in points
      if value > 0
        epoints.push({date: obj.date, value: value})
      value += parseFloat(obj.value)
      obj.value = value
      epoints.push(obj)
      if value < 0
        break

    window.updateData epoints
  reparse()
