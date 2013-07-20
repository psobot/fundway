transitionDelay = 500

maxYears = 10
endDate = new Date((new Date().getTime()) + (1000 * 60 * 60 * 24 * 365 * maxYears))

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

  existing = localStorage["__fundway_data"]
  if existing?
    data = JSON.parse localStorage["__fundway_data"]
  else
    data = [
      ["Date", "$", "Repeats"],
      ["2013-07-19", 6000, ""],
      ["2013-07-19", -600, "every 1 month"],
      ["2013-07-19", 400, "every 2 months"],
    ]

  isEmptyRow = (instance, row) ->
    rowData = instance.getData()[row]
    i = 0
    ilen = rowData.length
    
    while i < ilen
      return false  if rowData[i] != null
      i++
    true

  defaultValueRenderer = (instance, td, row, col, prop, value, cellProperties) ->
    args = $.extend(true, [], arguments)
    if args[5] == null and isEmptyRow(instance, row)
      args[5] = tpl[col]
      td.style.color = "#999"
    else
      td.style.color = ""
    Handsontable.TextCell.renderer.apply this, args
  tpl = [ "date", "value", "repeats?" ]

  container = $("#table")
  container.handsontable 
    data: data
    startRows: 10
    startCols: 3
    minSpareRows: 1
    contextMenu: true
    afterChange: (changes, source) ->
      if source == "edit"
        reparse()

    cells: (row, col, prop) ->
      cellProperties = {}
      cellProperties.type = renderer: defaultValueRenderer
      cellProperties
    
    beforeChange: (changes) ->
      instance = container.data("handsontable")
      ilen = changes.length
      clen = instance.colCount
      rowColumnSeen = {}
      rowsToFill = {}
      i = 0
      while i < ilen
        if changes[i][2] == null and changes[i][3] != null
          if isEmptyRow(instance, changes[i][0])
            rowColumnSeen[changes[i][0] + "/" + changes[i][1]] = true
            rowsToFill[changes[i][0]] = true
        i++
      for r of rowsToFill
        if rowsToFill.hasOwnProperty(r)
          c = 0
          while c < clen
            changes.push [ r, c, null, tpl[c] ]  unless rowColumnSeen[r + "/" + c]
            c++



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
    regex = /every (\d+ )?(days?|weeks?|months?|years?)/ig
    matches = regex.exec(repeat_words)
    return null if not matches?
    if matches.length == 3
      factor =
        switch matches[2].toLowerCase()
          when "day", "days" then 60 * 60 * 24
          when "week", "weeks" then 60 * 60 * 24 * 7
          when "month", "months" then 60 * 60 * 24 * 30
          when "year", "years" then 60 * 60 * 24 * 365
      if matches[1]?
        factor * parseInt(matches[1])
      else
        factor
    else
      null

  reparse = ->
    ht = $("#table").handsontable('getInstance')
    data = ht.getData()
    localStorage["__fundway_data"] = JSON.stringify(data)
    
    points = []

    # Turn our set of repetitive events into static, concrete data points.
    for row in data[1...-1]
      date = parseDate(row[0])
      value = row[1]
      interval = interval_from(row[2])
      continue unless (date? and value?)
      if interval?
        i = 0
        ndate = new Date(date.getTime() + (i * interval * 1000))
        while ndate < endDate
          points.push({
            date: ndate,
            value: value
          })
          i += 1
          ndate = new Date(date.getTime() + (i * interval * 1000))
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
      unless epoints.length == 0 and obj.value < 0
        epoints.push(obj)
      if obj.date > endDate
        $("#error .value").html("never!")
        break
      else if obj.value < 0 && epoints.length > 1
        $("#error .value").html("on #{obj.date}.")
        break
      else
        $("#error .value").html("some time more than #{maxYears} years from now.")

    window.updateData epoints
  reparse()
