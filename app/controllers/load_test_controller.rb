class LoadTestController < ApplicationController
  # This action will sleep for the specified number of seconds
  # Use it to simulate a slow endpoint that would trigger autoscaling
  def slow
    seconds = params.fetch(:seconds, 10).to_i
    sleep(seconds)
    render json: { status: "success", message: "Slept for #{seconds} seconds" }
  end

  # This action will create a specified number of threads that each sleep
  # Use it to simulate multiple concurrent slow requests
  def concurrent_slow
    threads_count = params.fetch(:threads, 5).to_i
    seconds = params.fetch(:seconds, 10).to_i

    threads = []
    threads_count.times do |i|
      threads << Thread.new do
        sleep(seconds)
      end
    end

    threads.each(&:join)

    render json: {
      status: "success",
      message: "Created #{threads_count} threads that each slept for #{seconds} seconds"
    }
  end

  # This action will enqueue a specified number of background jobs
  # Use it to test Judoscale's job queue monitoring
  def enqueue_jobs
    count = params.fetch(:count, 10).to_i
    seconds = params.fetch(:seconds, 10).to_i

    count.times do
      TestJob.perform_later(seconds)
    end

    render json: {
      status: "success",
      message: "Enqueued #{count} jobs that will each run for #{seconds} seconds"
    }
  end
end
