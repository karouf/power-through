function highlightArea(fn, start, end) {
  path = [];

  for(i = start; i < end; i += 0.01) {
    path.push([i, fn(i)]);
  }

  path.push([end, fn(end)]);
  path.push([end, 0]);
  path.push([start, 0]);
  return path;
}

function makeGraphVisible(exercise) {
  visibleGraphs = d3.select('div.exercise.visible');
  graph = d3.select('div.exercise.' + exercise);
  visibleGraphs.classed('visible', false);
  graph.classed('visible', true);
}

function fitData(fn, xDomain) {
  min = d3.min(xDomain());
  max = d3.max(xDomain());

  step = (max - min) / 100;

  data = new Array();

  for(i = min; i <= max; i += step) {
    data.push([i, fn(i)]);
  }

  return data;
}

var margin = {top: 30, right: 30, bottom: 30, left: 60},
    width = 960 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;

var xValue = function(d) { return d[0];}, // data -> value
    xScale = d3.scale.linear().range([0, width]), // value -> display
    xMap = function(d) { return xScale(xValue(d));}, // data -> display
    xAxis = d3.svg.axis().scale(xScale).tickSize(-height).tickSubdivide(true).orient("bottom");

var yValue = function(d) { return d[1];}, // data -> value
    yScale = d3.scale.linear().range([height, 0]), // value -> display
    yMap = function(d) { return yScale(yValue(d));}, // data -> display
    yAxis = d3.svg.axis().scale(yScale).tickSize(-width).orient("left");

var line = d3.svg.line()
  // assign the X function to plot our line as we wish
  .x(function(d,i) {
      // return the X coordinate where we want to plot this datapoint
      return xScale(parseFloat(d[0]));
      })
  .y(function(d) {
    // return the Y coordinate where we want to plot this datapoint
    return yScale(parseFloat(d[1]));
  })

highlight = d3.svg.area()
              .x(function(d) { return xScale(parseFloat(d[0])); })
              .y0(height)
              .y1(function(d) { return yScale(parseFloat(d[1])); });

d3.json('/data', function(error, json) {

  d3.select("body").append("select");
  dropdown = document.getElementsByTagName('select')[0];
  dropdown.addEventListener('change', function() {
    makeGraphVisible(dropdown.value);
  });

  json.forEach(function(exercise) {

    option = document.createElement('option');
    option.text = exercise.name;
    dropdown.add(option);

  
    exElement = d3.select("body")
                  .append('div')
                  .attr('class', 'exercise ' + exercise.name);
    exElement.append("h1").text(exercise.name);

    exercise.graphs.forEach(function(graph) {
      if(graph.unprocessable) {
        exElement.append('p').text(graph.unprocessable.message);
      } else {
        data = graph.data;
        fn = new Function('x', 'return ' + graph.fn);
  
        xScale.domain([0, d3.max(data, xValue)+1]);
        yScale.domain([0, d3.max([fn(0)+fn(0)*0.1,d3.max(data, yValue)+d3.max(data, yValue)*0.1])]);
        //yScale.domain([0, d3.max(data, yValue)+1]);

        svg = exElement.append("svg")
                .attr('class', exercise.name)
                .attr("width", width + margin.left + margin.right)
                .attr("height", height + margin.top + margin.bottom)
              .append("g")
                .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

        svg.append('text').text(graph.title).attr('transform', 'translate(15, -15)');

        if(graph.powerOverlay) {
          svg.append("path")
             .attr('class', 'highlight')
             .attr("d", highlight(highlightArea(fn, graph.powerOverlay.rangeStart[0], graph.powerOverlay.rangeEnd[0])));
          svg.append("path")
             .attr('class', 'highlight peak')
             .attr("d", line([[graph.powerOverlay.peak[0],graph.powerOverlay.peak[1]],[graph.powerOverlay.peak[0],0]]));
          svg.append("path")
             .attr('class', 'highlight border')
             .attr("d", line([[graph.powerOverlay.rangeStart[0],graph.powerOverlay.rangeStart[1]],[graph.powerOverlay.rangeStart[0],0]]));
          svg.append("path")
             .attr('class', 'highlight border')
             .attr("d", line([[graph.powerOverlay.rangeEnd[0],graph.powerOverlay.rangeEnd[1]],[graph.powerOverlay.rangeEnd[0],0]]));
        }

        svg.append("g")
           .attr("class", "x axis")
           .attr("transform", "translate(0," + height + ")")
           .call(xAxis)
         .append("text")
           .attr("class", "label")
           .attr("x", width)
           .attr("y", -6)
           .style("text-anchor", "end")
           .text(graph.x_axis);
  
        svg.append("g")
           .attr("class", "y axis")
           .call(yAxis)
         .append("text")
           .attr("class", "label")
           .attr("transform", "rotate(-90)")
           .attr("y", 6)
           .attr("dy", ".71em")
           .style("text-anchor", "end")
           .text(graph.y_axis);
  
        svg.selectAll(".dot")
           .data(data)
         .enter().append("circle")
           .attr("class", "dot")
           .attr("r", 3.5)
           .attr("cx", xMap)
           .attr("cy", yMap)
           .style("fill", '#ff0000');
  
        svg.append("path").attr("d", line(fitData(fn, xScale.domain)));
      }  
    });
  });

  makeGraphVisible(dropdown.value);

});

