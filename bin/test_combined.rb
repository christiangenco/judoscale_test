#!/usr/bin/env ruby
# This script tests both web requests and job queues simultaneously for maximum load

require 'net/http'
require 'uri'
require 'json'
require 'optparse'

options = {
  base_url: 'https://judoscale-test.onrender.com',
  web_concurrency: 30,
  web_requests: 100,
  web_sleep_seconds: 20,
  web_delay: 0.1,
  job_count: 50,
  job_duration: 15,
  job_batches: 5,
  job_delay: 2
}

OptionParser.new do |opts|
  opts.banner = "Usage: bin/test_combined.rb [options]"

  opts.on("--url URL", "Base URL (default: #{options[:base_url]})") do |url|
    options[:base_url] = url
  end

  opts.on("--web-concurrency N", Integer, "Web concurrency (default: #{options[:web_concurrency]})") do |n|
    options[:web_concurrency] = n
  end

  opts.on("--web-requests N", Integer, "Total web requests (default: #{options[:web_requests]})") do |n|
    options[:web_requests] = n
  end

  opts.on("--web-sleep SECONDS", Integer, "Web request sleep seconds (default: #{options[:web_sleep_seconds]})") do |s|
    options[:web_sleep_seconds] = s
  end

  opts.on("--job-count N", Integer, "Jobs per batch (default: #{options[:job_count]})") do |n|
    options[:job_count] = n
  end

  opts.on("--job-duration SECONDS", Integer, "Job duration in seconds (default: #{options[:job_duration]})") do |s|
    options[:job_duration] = s
  end

  opts.on("--job-batches N", Integer, "Number of job batches (default: #{options[:job_batches]})") do |n|
    options[:job_batches] = n
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

puts "Starting combined load test with the following options:"
puts "Base URL: #{options[:base_url]}"
puts "Web concurrency: #{options[:web_concurrency]}"
puts "Total web requests: #{options[:web_requests]}"
puts "Web sleep seconds: #{options[:web_sleep_seconds]}"
puts "Jobs per batch: #{options[:job_count]}"
puts "Job duration: #{options[:job_duration]} seconds"
puts "Number of job batches: #{options[:job_batches]}"
puts

# Start web requests in a separate thread
web_thread = Thread.new do
  web_url = "#{options[:base_url]}/load_test/slow?seconds=#{options[:web_sleep_seconds]}"

  completed = 0
  active = 0
  start_time = Time.now

  mutex = Mutex.new
  threads = []

  options[:web_requests].times do |i|
    # Wait until we have a free slot (concurrency limit)
    while true
      mutex.synchronize do
        break if active < options[:web_concurrency]
      end
      sleep 0.1
    end

    # Start a new request
    mutex.synchronize { active += 1 }

    threads << Thread.new do
      begin
        request_start = Time.now
        response = Net::HTTP.get_response(URI.parse(web_url))
        request_end = Time.now

        mutex.synchronize do
          completed += 1
          active -= 1

          elapsed = request_end - request_start
          progress = (completed.to_f / options[:web_requests] * 100).round(1)

          puts "[WEB #{completed}/#{options[:web_requests]} - #{progress}%] Request completed in #{elapsed.round(2)}s with status #{response.code}"
        end
      rescue => e
        mutex.synchronize do
          active -= 1
          puts "Web Error: #{e.message}"
        end
      end
    end

    # Add delay between starting requests
    sleep options[:web_delay]
  end

  # Wait for all threads to complete
  threads.each(&:join)

  total_time = Time.now - start_time
  puts "\nWeb load test completed in #{total_time.round(2)} seconds"
  puts "Average response time: #{(total_time / completed).round(2)} seconds"
end

# Start job queue test
job_thread = Thread.new do
  job_url = "#{options[:base_url]}/load_test/enqueue_jobs"
  total_jobs = 0

  options[:job_batches].times do |batch|
    uri = URI.parse(job_url)
    params = { count: options[:job_count], seconds: options[:job_duration] }
    uri.query = URI.encode_www_form(params)

    begin
      response = Net::HTTP.get_response(uri)

      if response.code == "200"
        total_jobs += options[:job_count]
        puts "[JOBS] Batch #{batch + 1}/#{options[:job_batches]}: Enqueued #{options[:job_count]} jobs. Total: #{total_jobs} jobs"
      else
        puts "[JOBS] Batch #{batch + 1}/#{options[:job_batches]}: Error - HTTP #{response.code}"
        puts response.body
      end
    rescue => e
      puts "[JOBS] Error: #{e.message}"
    end

    # Wait before sending the next batch
    if batch < options[:job_batches] - 1
      puts "[JOBS] Waiting #{options[:job_delay]} seconds before next batch..."
      sleep options[:job_delay]
    end
  end

  puts "\n[JOBS] Job queue test completed. Enqueued a total of #{total_jobs} jobs."
  puts "[JOBS] Each job will run for approximately #{options[:job_duration]} seconds."
end

# Wait for both tests to complete
web_thread.join
job_thread.join

puts "\nCombined load test completed!"
puts "Check your Judoscale dashboard to see the metrics."
