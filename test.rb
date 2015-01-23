#!/usr/bin/env ruby

require 'csv'
require 'gsl'
require 'pp'

maxes = {}
Dir.new('data').each do |entry|
  pp entry
  if File.file?("data/#{entry}")
    CSV.foreach("data/#{entry}") do |row|
      if row[3] == 'DEADLIFT_BARBELL'
        maxes[row[4]] ||= { velocity: 0, force: 0, power: 0 }
        maxes[row[4]][:velocity] = row[12].to_f if row[12].to_f > maxes[row[4]][:velocity]
        maxes[row[4]][:force] = row[10].to_f if row[10].to_f > maxes[row[4]][:force]
        maxes[row[4]][:power] = row[11].to_f if row[11].to_f > maxes[row[4]][:power]
      end
    end
  end
end

pp maxes

data = []
maxes.each do |k,v|
  data << [v[:velocity], v[:force]]
end

x = GSL::Vector.alloc(data.map{ |i| i.first })
y = GSL::Vector.alloc(data.map{ |i| i.last })

c0, c1, cov00, cov01, cov11, chisq = GSL::Fit.linear(x, y)

printf("# best fit: Y = %g + %g X\n", c0, c1);
printf("# covariance matrix:\n");
printf("# [ %g, %g\n#   %g, %g]\n",
               cov00, cov01, cov01, cov11);
printf("# chisq = %g\n", chisq);

graphs = [
          { fn: "#{c0} + #{c1} x",
            data: data
          }
        ]

pp graphs
