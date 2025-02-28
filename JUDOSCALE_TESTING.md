# Testing Judoscale Autoscaling

This document provides instructions on how to test Judoscale autoscaling with this application.

## Prerequisites

1. Install the required gems:

   ```
   bundle install
   ```

2. Set your Judoscale API key:

   ```
   export JUDOSCALE_API_KEY=your_api_key_here
   ```

3. Make sure your application is configured to use Puma with multiple workers:
   ```
   export WEB_CONCURRENCY=2  # Set to the number of workers you want to start with
   export RAILS_MAX_THREADS=5  # Set the number of threads per worker
   ```

## Running the Tests

You can run the tests against either your local server or the remote server at https://judoscale-test.onrender.com.

### Web Request Testing

1. If testing locally, start your Rails server:

   ```
   bundle exec rails server
   ```

   If testing against the remote server, you can skip this step.

2. In a terminal, run the web request test script:

   ```
   bin/test_autoscaling.rb
   ```

   This will send 100 requests with 30 concurrent connections to the slow endpoint.

3. You can customize the test parameters:

   ```
   bin/test_autoscaling.rb --help
   ```

   Example with custom parameters:

   ```
   bin/test_autoscaling.rb --concurrency 40 --requests 150 --sleep 20
   ```

   To test against a different URL:

   ```
   bin/test_autoscaling.rb --url http://localhost:3000/load_test/slow
   ```

### Background Job Testing

1. If testing locally, start your Rails server with Solid Queue running in the same process:

   ```
   export SOLID_QUEUE_IN_PUMA=true
   bundle exec rails server
   ```

   If testing against the remote server, you can skip this step.

2. In a terminal, run the job queue test script:

   ```
   bin/test_job_queue.rb
   ```

   This will enqueue 250 jobs (5 batches of 50 jobs) that each run for 15 seconds.

3. You can customize the test parameters:

   ```
   bin/test_job_queue.rb --help
   ```

   Example with custom parameters:

   ```
   bin/test_job_queue.rb --count 100 --duration 20 --batches 10
   ```

   To test against a different URL:

   ```
   bin/test_job_queue.rb --url http://localhost:3000/load_test/enqueue_jobs
   ```

### Combined Testing (Maximum Load)

For the most effective testing, you can run both web request and job queue tests simultaneously:

```
bin/test_combined.rb
```

This will run both tests in parallel, creating maximum load on your application.

You can customize the parameters:

```
bin/test_combined.rb --help
```

Example with custom parameters:

```
bin/test_combined.rb --web-concurrency 40 --web-requests 150 --job-count 100 --job-batches 10
```

To test against a different URL:

```
bin/test_combined.rb --url http://localhost:3000
```

## What to Look For

1. **Judoscale Dashboard**: Check your Judoscale dashboard to see if it's detecting the increased load and recommending more workers.

2. **Logs**: Look for Judoscale log entries in your application logs that indicate metrics being sent and scaling recommendations.

3. **Performance**: Monitor how your application performs under load with different numbers of workers.

## Manual Testing

You can also manually test the endpoints:

1. Single slow request:

   ```
   curl "https://judoscale-test.onrender.com/load_test/slow?seconds=10"
   ```

2. Concurrent slow requests:

   ```
   curl "https://judoscale-test.onrender.com/load_test/concurrent_slow?threads=5&seconds=10"
   ```

3. Enqueue background jobs:
   ```
   curl "https://judoscale-test.onrender.com/load_test/enqueue_jobs?count=20&seconds=15"
   ```

## Troubleshooting

- If Judoscale doesn't seem to be working, check that your API key is set correctly.
- Verify that the Judoscale gems are properly installed and loaded.
- Check your application logs for any Judoscale-related errors.
- Make sure your Puma server is configured to use multiple workers (WEB_CONCURRENCY > 1).
- Ensure that Solid Queue is running (either in a separate process or in Puma with SOLID_QUEUE_IN_PUMA=true).
- When testing against the remote server, make sure it's running and accessible.

## How It Works

The test creates artificial load by making requests to endpoints that sleep for a specified duration and by enqueuing background jobs that also sleep. This simulates slow requests and jobs that would tie up your application's threads and workers.

Judoscale monitors these metrics and recommends scaling your application based on the current load. In a production environment with proper autoscaling setup (like Heroku autoscaling), this would trigger the addition of more dynos/workers to handle the increased load.
