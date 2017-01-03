require 'aws-sdk'
require 'rukins/core/credentials'

module Rukins
  class Delete

    def initialize(options)
      @options = options
      credentials = Rukins::Credentials.new(@options)
      @cfn = Aws::CloudFormation::Client.new(credentials.value)
    end

    def run
      delete
      wait if @options.wait
    end

    def delete
      begin
        @cfn.delete_stack({stack_name: @options.stack_name})
        puts "INFO: Deleting stack #{@options.stack_name}"
      rescue => e
        abort "ERROR: #{e.class} #{e}"
      end
    end

    def wait
      begin
        started_at = Time.now
        @cfn.wait_until(:stack_delete_complete, stack_name: @options.stack_name) do |w|
          w.max_attempts = nil
          w.before_wait do |attempts, response|
            puts "STATUS: #{response.stacks[0].stack_status}"
            throw :failure if Time.now - started_at > 3600
          end
        end
      rescue Aws::Waiters::Errors::WaiterFailed => e
        abort "ERROR: #{e}"
      end
    end

  end
end
