require 'sinatra'
require 'csv'
require 'gsl'
require 'json'
require 'date'
require 'pp'

get '/' do
  erb :index
end

get '/aged' do
  erb :aged
end

get '/agedjson' do
  show_max = true

  exercises = []
  Dir.new('data/all').each do |entry|
    if File.file?("data/all/#{entry}")
      match = entry.match(/.*([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2})\.csv$/)

      if match[1]
        date = DateTime.strptime(match[1], '%Y-%m-%d_%H-%M')

        CSV.foreach("data/all/#{entry}", headers: true, return_headers: false) do |row|
          exercise = exercises.select{ |e| e[:name] == row[3] }.first
          if exercise.nil?
            exercise = { name: row[3], max: [], avg: [] }
            exercises << exercise
          end

          # Store data points with data
          exercise[:max] << { load: row[4], velocity: row[12], force: row[10], power: row[11], date: date.strftime('%Y-%m-%dT%H:%M:%S') }
          exercise[:avg] << { load: row[4], velocity: row[9], force: row[7], power: row[8], date: date.strftime('%Y-%m-%dT%H:%M:%S') }
        end
      end
    end
  end

  exos = []
  exercises.each do |exercise|
    exo = {}
    exo[:name] = exercise[:name]
    exo[:graphs] = []

    vel_force_data = []
    if show_max
      exercise[:max].each do |v|
        vel_force_data << [v[:velocity], v[:force], v[:date]]
      end
    else
      exercise[:avg].each do |v|
        vel_force_data << [v[:velocity], v[:force], v[:date]]
      end
    end

    vel_power_data = []
    if show_max
      exercise[:max].each do |v|
        vel_power_data << [v[:velocity], v[:power], v[:date]]
      end
    else
      exercise[:avg].each do |v|
        vel_power_data << [v[:velocity], v[:power], v[:date]]
      end
    end

    exo[:graphs] << { title: 'Velocity-force aged data',
                      x_axis: 'Velocity (m/s)',
                      y_axis: 'Force (N)',
                      data: vel_force_data
                    }

    exos << exo
  end

  exos.to_json
end

get '/data' do
  show_all = true
  show_wrong = true

  exercises = []
  Dir.new('data/all').each do |entry|
    if File.file?("data/all/#{entry}")
      CSV.foreach("data/all/#{entry}", headers: true, return_headers: false) do |row|
        exercise = exercises.select{ |e| e[:name] == row[3] }.first
        if exercise.nil?
          exercise = { name: row[3], velocity: { peak: { max: {}, all: [] }, avg: { max: {}, all: [] } }, load: { peak: { max: {}, all: [] }, avg: { max: {}, all: [] } } }
          exercises << exercise
        end

        exercise[:velocity][:peak][:max][row[4]] ||= { velocity: 0, force: 0, power: 0 }
        exercise[:velocity][:peak][:max][row[4]][:velocity] = row[12].to_f if row[12].to_f > exercise[:velocity][:peak][:max][row[4]][:velocity]
        exercise[:velocity][:peak][:max][row[4]][:force] = row[10].to_f if row[10].to_f > exercise[:velocity][:peak][:max][row[4]][:force]
        exercise[:velocity][:peak][:max][row[4]][:power] = row[11].to_f if row[11].to_f > exercise[:velocity][:peak][:max][row[4]][:power]

        exercise[:velocity][:peak][:all] << { load: row[4].to_f, velocity: row[12].to_f, force: row[10].to_f, power: row[11].to_f }

        exercise[:velocity][:avg][:max][row[4]] ||= { velocity: 0, force: 0, power: 0 }
        exercise[:velocity][:avg][:max][row[4]][:velocity] = row[9].to_f if row[9].to_f > exercise[:velocity][:avg][:max][row[4]][:velocity]
        exercise[:velocity][:avg][:max][row[4]][:force] = row[7].to_f if row[7].to_f > exercise[:velocity][:avg][:max][row[4]][:force]
        exercise[:velocity][:avg][:max][row[4]][:power] = row[8].to_f if row[8].to_f > exercise[:velocity][:avg][:max][row[4]][:power]

        exercise[:velocity][:avg][:all] << { load: row[4].to_f, velocity: row[9].to_f, force: row[7].to_f, power: row[8].to_f }

        exercise[:load][:peak][:max][row[4]] ||= { velocity: 0, force: 0, power: 0 }
        exercise[:load][:peak][:max][row[4]][:velocity] = row[12].to_f if row[12].to_f > exercise[:load][:peak][:max][row[4]][:velocity]
        exercise[:load][:peak][:max][row[4]][:force] = row[10].to_f if row[10].to_f > exercise[:load][:peak][:max][row[4]][:force]
        exercise[:load][:peak][:max][row[4]][:power] = row[11].to_f if row[11].to_f > exercise[:load][:peak][:max][row[4]][:power]

        exercise[:load][:peak][:all] << { velocity: row[12].to_f, force: row[10].to_f, power: row[11].to_f }

        exercise[:load][:avg][:max][row[4]] ||= { velocity: 0, force: 0, power: 0 }
        exercise[:load][:avg][:max][row[4]][:load] = row[4].to_f if row[4].to_f > exercise[:load][:avg][:max][row[4]][:velocity]
        exercise[:load][:avg][:max][row[4]][:force] = row[7].to_f if row[7].to_f > exercise[:load][:avg][:max][row[4]][:force]
        exercise[:load][:avg][:max][row[4]][:power] = row[8].to_f if row[8].to_f > exercise[:load][:avg][:max][row[4]][:power]

        exercise[:load][:avg][:all] << { load: row[4].to_f, force: row[7].to_f, power: row[8].to_f }
      end
    end
  end

  exos = []
  exercises.each do |exercise|
    exo = {}
    exo[:name] = exercise[:name]
    exo[:graphs] = []

    vel_force_data = []
    if show_all
      exercise[:velocity][:avg][:all].each do |v|
        vel_force_data << [v[:velocity], v[:force]]
      end
    else
      exercise[:velocity][:avg][:max].each do |k,v|
        vel_force_data << [v[:velocity], v[:force]]
      end
    end

    vel_power_data = []
    if show_all
      exercise[:velocity][:avg][:all].each do |v|
        vel_power_data << [v[:velocity], v[:power]]
      end
    else
      exercise[:velocity][:avg][:max].each do |k,v|
        vel_power_data << [v[:velocity], v[:power]]
      end
    end
    vel_power_data << [0, 0]

    load_force_data = []
    if show_all
      exercise[:load][:avg][:all].each do |v|
        load_force_data << [v[:load], v[:force]]
      end
    else
      exercise[:load][:avg][:max].each do |k,v|
        load_force_data << [k.to_f, v[:force]]
      end
    end

    load_power_data = []
    if show_all
      exercise[:load][:avg][:all].each do |v|
        load_power_data << [v[:load], v[:power]]
      end
    else
      exercise[:load][:avg][:max].each do |k,v|
        load_power_data << [k.to_f, v[:power]]
      end
    end
    load_power_data << [0, 0]

    x = GSL::Vector.alloc(vel_force_data.map{ |i| i.first })
    y = GSL::Vector.alloc(vel_force_data.map{ |i| i.last })

    if x.size > 1
      c0, c1, cov00, cov01, cov11, chisq = GSL::Fit.linear(x, y)

      if c1 < 0 || show_wrong
        exo[:graphs] << { fn: "#{c0} + #{c1} * x",
                          title: 'Velocity-force curve',
                          x_axis: 'Velocity (m/s)',
                          y_axis: 'Force (N)',
                          data: vel_force_data
                        }
      else
        exo[:graphs] << { unprocessable: { message: 'Data is not spread enough over the velocity range to be able to build a realistic velocity-force curve.' } }
      end
    else
      exo[:graphs] << { unprocessable: { message: 'We need at least 2 data points to be able to build the velocity-force curve.' } }
    end

    x = GSL::Vector.alloc(vel_power_data.map{ |i| i.first })
    y = GSL::Vector.alloc(vel_power_data.map{ |i| i.last })

    if x.size > 2
      coef, err, chisq, status = GSL::MultiFit.polyfit(x, y, 2)

      power_peak = [0,0]
      (0..10).step(0.01) do |x|
        y = coef[0] + coef[1]*x + coef[2]*x*x
        power_peak = [x, y] if y > power_peak[1]
      end
      power_range = { begin: [0, 0], end: [10, 0] }
      (0..10).step(0.01) do |x|
        y = coef[0] + coef[1]*x + coef[2]*x*x
        power_range[:begin] = [x, y] if x < power_peak[0] && y < (power_peak[1]*0.99)
        power_range[:end] = [x, y] if x > power_peak[0] && y > power_peak[1]*0.99
      end

      if coef[2] < 0 || show_wrong
        exo[:graphs] << { fn: "#{coef[0]} + #{coef[1]} * x + #{coef[2]} * x*x",
                          title: 'Velocity-power curve',
                          x_axis: 'Velocity (m/s)',
                          y_axis: 'Power (W)',
                          data: vel_power_data,
                          powerOverlay: {
                            peak: power_peak,
                            rangeStart: power_range[:begin],
                            rangeEnd: power_range[:end]
                          }
                        }
      else
        exo[:graphs] << { unprocessable: { message: 'Data is not spread enough over the velocity range to be able to build a realistic velocity-power curve.' } }
      end
    else
      exo[:graphs] << { unprocessable: { message: 'We need at least 2 data points to be able to build the velocity-power curve.' } }
    end

    x = GSL::Vector.alloc(load_force_data.map{ |i| i.first })
    y = GSL::Vector.alloc(load_force_data.map{ |i| i.last })

    if x.size > 1
      c0, c1, cov00, cov01, cov11, chisq = GSL::Fit.linear(x, y)

      if c1 > 0 || show_wrong
        exo[:graphs] << { fn: "#{c0} + #{c1} * x",
                          title: 'Load-force curve',
                          x_axis: 'Load (kg)',
                          y_axis: 'Force (N)',
                          data: load_force_data
                        }
      else
        exo[:graphs] << { unprocessable: { message: 'Data is not spread enough over the load range to be able to build a realistic load-force curve.' } }
      end
    else
      exo[:graphs] << { unprocessable: { message: 'We need at least 2 data points to be able to build the load-force curve.' } }
    end

    x = GSL::Vector.alloc(load_power_data.map{ |i| i.first })
    y = GSL::Vector.alloc(load_power_data.map{ |i| i.last })

    if x.size > 2
      coef, err, chisq, status = GSL::MultiFit.polyfit(x, y, 2)

      power_peak = [0,0]
      (0..300).step(0.5) do |x|
        y = coef[0] + coef[1]*x + coef[2]*x*x
        power_peak = [x, y] if y > power_peak[1]
      end
      power_range = { begin: [0, 0], end: [300, 0] }
      (0..300).step(0.5) do |x|
        y = coef[0] + coef[1]*x + coef[2]*x*x
        power_range[:begin] = [x, y] if x < power_peak[0] && y < (power_peak[1]*0.99)
        power_range[:end] = [x, y] if x > power_peak[0] && y > power_peak[1]*0.99
      end

      if coef[2] < 0 || show_wrong
        exo[:graphs] << { fn: "#{coef[0]} + #{coef[1]} * x + #{coef[2]} * x*x",
                          title: 'Load-power curve',
                          x_axis: 'Load (kg)',
                          y_axis: 'Power (W)',
                          data: load_power_data,
                          powerOverlay: {
                            peak: power_peak,
                            rangeStart: power_range[:begin],
                            rangeEnd: power_range[:end]
                          }
                        }
      else
        exo[:graphs] << { unprocessable: { message: 'Data is not spread enough over the load range to be able to build a realistic load-power curve.' } }
      end
    else
      exo[:graphs] << { unprocessable: { message: 'We need at least 2 data points to be able to build the load-power curve.' } }
    end

    exos << exo
  end

  exos.to_json
end
