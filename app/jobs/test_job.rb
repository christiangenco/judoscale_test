class TestJob < ApplicationJob
  queue_as :default

  def perform(sleep_seconds = 10)
    # Simulate a long-running job
    sleep(sleep_seconds)
  end
end
