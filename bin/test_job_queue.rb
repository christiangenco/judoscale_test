#!/usr/bin/env ruby
# This script tests Judoscale's job queue monitoring by enqueuing many jobs

require 'net/http'
require 'uri'
require 'json'
require 'optparse'

options = {
  url: 'https://judoscale-test.onrender.com/load_test/enqueue_jobs',
  count: 50,
  job_duration: 15,
  batches: 5,
  delay_between_batches: 2
}

OptionParser.new do |opts|
  opts.banner = "Usage: bin/test_job_queue.rb [options]"

  opts.on("-u", "--url URL", "URL to enqueue jobs (default: #{options[:url]})") do |url|
    options[:url] = url
  end

  opts.on("-c", "--count N", Integer, "Number of jobs per batch (default: #{options[:count]})") do |n|
    options[:count] = n
  end

  opts.on("-d", "--duration SECONDS", Integer, "Duration of each job in seconds (default: #{options[:job_duration]})") do |s|
    options[:job_duration] = s
  end

  opts.on("-b", "--batches N", Integer, "Number of batches to send (default: #{options[:batches]})") do |n|
    options[:batches] = n
  end

  opts.on("-w", "--wait SECONDS", Integer, "Seconds to wait between batches (default: #{options[:delay_between_batches]})") do |s|
    options[:delay_between_batches] = s
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

puts "Starting job queue test with the following options:"
puts "URL: #{options[:url]}"
puts "Jobs per batch: #{options[:count]}"
puts "Job duration: #{options[:job_duration]} seconds"
puts "Number of batches: #{options[:batches]}"
puts "Delay between batches: #{options[:delay_between_batches]} seconds"
puts

total_jobs = 0

options[:batches].times do |batch|
  uri = URI.parse(options[:url])
  params = { count: options[:count], seconds: options[:job_duration] }
  uri.query = URI.encode_www_form(params)

  begin
    response = Net::HTTP.get_response(uri)

    if response.code == "200"
      total_jobs += options[:count]
      puts "Batch #{batch + 1}/#{options[:batches]}: Enqueued #{options[:count]} jobs. Total: #{total_jobs} jobs"
    else
      puts "Batch #{batch + 1}/#{options[:batches]}: Error - HTTP #{response.code}"
      puts response.body
    end
  rescue => e
    puts "Error: #{e.message}"
  end

  # Wait before sending the next batch
  if batch < options[:batches] - 1
    puts "Waiting #{options[:delay_between_batches]} seconds before next batch..."
    sleep options[:delay_between_batches]
  end
end

puts "\nJob queue test completed. Enqueued a total of #{total_jobs} jobs."
puts "Each job will run for approximately #{options[:job_duration]} seconds."
puts "Check your Judoscale dashboard to see the queue metrics."
