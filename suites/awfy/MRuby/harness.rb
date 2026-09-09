# Main entry point: instantiates the requested benchmark class and iterates
# it num_iterations times, timing each run.
klass = ARGV[0]
num_iterations = (ARGV[1] || 1).to_i
inner_iterations = (ARGV[2] || 1).to_i

bench = Object.const_get(klass).new
total = 0

num_iterations.times do
  start_time = Process.clock_gettime(:monotonic)
  raise 'Benchmark failed with incorrect result' unless bench.inner_benchmark_loop(inner_iterations)
  end_time = Process.clock_gettime(:monotonic)

  run_time = ((end_time - start_time) * 1_000_000).to_i
  puts "#{klass}: iterations=1 runtime: #{run_time}us"
  total += run_time
end

puts "#{klass}: iterations=#{num_iterations} average: #{total / num_iterations}us total: #{total}us\n"
puts "Total Runtime: #{total}us"
