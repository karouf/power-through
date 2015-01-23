function makeGraphVisible(exercise) {
  visibleGraphs = d3.select('div.exercise.visible');
  graph = d3.select('div.exercise.' + exercise);
  visibleGraphs.classed('visible', false);
  graph.classed('visible', true);
}

var margin = {top: 30, right: 30, bottom: 30, left: 60},
    width = 960 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;

var datetime = d3.time.format('%Y-%m-%dT%H:%M:%S');

var xValue = function(d) { return parseFloat(d[0]);}, // data -> value
    xScale = d3.scale.linear().range([0, width]), // value -> display
    xMap = function(d) { return xScale(xValue(d));}, // data -> display
    xAxis = d3.svg.axis().scale(xScale).tickSize(-height).tickSubdivide(true).orient("bottom");

var yValue = function(d) { return parseFloat(d[1]);}, // data -> value
    yScale = d3.scale.linear().range([height, 0]), // value -> display
    yMap = function(d) { return yScale(yValue(d));}, // data -> display
    yAxis = d3.svg.axis().scale(yScale).tickSize(-width).orient("left");

var opacityValue = function(d) { return datetime.parse(d[2]);}, // data -> value
    opacityScale = d3.time.scale().range([0, 1]), // value -> display
    opacityMap = function(d) { return opacityScale(opacityValue(d));}; // data -> display

d3.json('/agedjson', function(error, json) {

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
      data = graph.data;

      xScale.domain([0, d3.max(data, xValue)+d3.max(data, xValue)*0.1]);
      yScale.domain([0, d3.max(data, yValue)+d3.max(data, yValue)*0.1]);
      opacityScale.domain([d3.min(data, opacityValue), d3.max(data, opacityValue)]);

      svg = exElement.append("svg")
              .attr('class', exercise.name)
              .attr("width", width + margin.left + margin.right)
              .attr("height", height + margin.top + margin.bottom)
            .append("g")
              .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

      svg.append('text').text(graph.title).attr('transform', 'translate(15, -15)');

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
         .style("fill", '#ff0000')
         .style('opacity', opacityMap);
    });
  });

  makeGraphVisible(dropdown.value);

});
