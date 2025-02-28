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

## Running the Test

1. Start your Rails server:

   ```
   bundle exec rails server
   ```

2. Visit the home page at http://localhost:3000 to access the testing interface with convenient links to the test endpoints.

3. In a separate terminal, run the autoscaling test script:

   ```
   bin/test_autoscaling.rb
   ```

   This will send 50 requests with 10 concurrent connections to the slow endpoint.

4. You can customize the test parameters:

   ```
   bin/test_autoscaling.rb --help
   ```

   Example with custom parameters:

   ```
   bin/test_autoscaling.rb --concurrency 20 --requests 100 --sleep 15
   ```

## What to Look For

1. **Judoscale Dashboard**: Check your Judoscale dashboard to see if it's detecting the increased load and recommending more workers.

2. **Logs**: Look for Judoscale log entries in your application logs that indicate metrics being sent and scaling recommendations.

3. **Performance**: Monitor how your application performs under load with different numbers of workers.

## Manual Testing

You can also manually test the slow endpoints:

1. Single slow request:

   ```
   curl "http://localhost:3000/load_test/slow?seconds=10"
   ```

2. Concurrent slow requests:
   ```
   curl "http://localhost:3000/load_test/concurrent_slow?threads=5&seconds=10"
   ```

## Troubleshooting

- If Judoscale doesn't seem to be working, check that your API key is set correctly.
- Verify that the Judoscale gems are properly installed and loaded.
- Check your application logs for any Judoscale-related errors.
- Make sure your Puma server is configured to use multiple workers (WEB_CONCURRENCY > 1).

## How It Works

The test creates artificial load by making requests to endpoints that sleep for a specified duration. This simulates slow requests that would tie up your application's threads and workers.

Judoscale monitors these metrics and recommends scaling your application based on the current load. In a production environment with proper autoscaling setup (like Heroku autoscaling), this would trigger the addition of more dynos/workers to handle the increased load.
