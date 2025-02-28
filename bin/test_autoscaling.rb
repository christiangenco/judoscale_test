#!/usr/bin/env ruby
# This script simulates heavy load on the application to test Judoscale autoscaling

require 'net/http'
require 'uri'
require 'json'
require 'optparse'

options = {
  url: 'http://localhost:3000/load_test/slow',
  concurrency: 10,
  requests: 50,
  sleep_seconds: 10,
  delay: 0.5
}

OptionParser.new do |opts|
  opts.banner = "Usage: bin/test_autoscaling.rb [options]"

  opts.on("-u", "--url URL", "URL to test (default: #{options[:url]})") do |url|
    options[:url] = url
  end

  opts.on("-c", "--concurrency N", Integer, "Number of concurrent requests (default: #{options[:concurrency]})") do |n|
    options[:concurrency] = n
  end

  opts.on("-n", "--requests N", Integer, "Total number of requests (default: #{options[:requests]})") do |n|
    options[:requests] = n
  end

  opts.on("-s", "--sleep SECONDS", Integer, "Seconds to sleep in each request (default: #{options[:sleep_seconds]})") do |s|
    options[:sleep_seconds] = s
  end

  opts.on("-d", "--delay SECONDS", Float, "Delay between starting new requests (default: #{options[:delay]})") do |d|
    options[:delay] = d
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

puts "Starting load test with the following options:"
puts "URL: #{options[:url]}"
puts "Concurrency: #{options[:concurrency]}"
puts "Total requests: #{options[:requests]}"
puts "Sleep seconds: #{options[:sleep_seconds]}"
puts "Delay between requests: #{options[:delay]}"
puts

# Add sleep parameter to URL if it's our load_test endpoint
uri = URI.parse(options[:url])
if uri.path.include?('load_test')
  params = URI.decode_www_form(uri.query || '')
  params << ['seconds', options[:sleep_seconds]]
  uri.query = URI.encode_www_form(params)
  options[:url] = uri.to_s
end

completed = 0
active = 0
start_time = Time.now

mutex = Mutex.new
threads = []

options[:requests].times do |i|
  # Wait until we have a free slot (concurrency limit)
  while true
    mutex.synchronize do
      break if active < options[:concurrency]
    end
    sleep 0.1
  end

  # Start a new request
  mutex.synchronize { active += 1 }

  threads << Thread.new do
    begin
      request_start = Time.now
      response = Net::HTTP.get_response(URI.parse(options[:url]))
      request_end = Time.now

      mutex.synchronize do
        completed += 1
        active -= 1

        elapsed = request_end - request_start
        progress = (completed.to_f / options[:requests] * 100).round(1)

        puts "[#{completed}/#{options[:requests]} - #{progress}%] Request completed in #{elapsed.round(2)}s with status #{response.code}"
      end
    rescue => e
      mutex.synchronize do
        active -= 1
        puts "Error: #{e.message}"
      end
    end
  end

  # Add delay between starting requests
  sleep options[:delay]
end

# Wait for all threads to complete
threads.each(&:join)

total_time = Time.now - start_time
puts "\nLoad test completed in #{total_time.round(2)} seconds"
puts "Average response time: #{(total_time / completed).round(2)} seconds"
