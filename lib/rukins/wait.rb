require 'aws-sdk'
require 'rukins/core/credentials'
require 'rukins/core/utils'

module Rukins
  class Wait

    def initialize(options)
      @options = options
      @config  = Rukins::Utils.load_default_params
      credentials = Rukins::Credentials.new(@options)
      @cfn = Aws::CloudFormation::Client.new(credentials.value)
    end

    def run
      wait_for_cfn(@options.stack_name)
    end

    def wait_for_cfn(stack_name)
      puts "INFO: waiting for cloudformation for environment - #{stack_name}"
      stacks = []

      # check stack status
      completed = false
      success = false

      until completed
        begin
          stacks = @cfn.list_stack_resources(stack_name: stack_name).stack_resource_summaries
        rescue
          ## Fix
          # Fall back to using stack id instead of stack name
          # (for deleted stacks, the SDK expects the stack ID instead of the stack name as an identifier)
          inactiveStacks = @cfn.list_stacks({stack_status_filter: ["DELETE_IN_PROGRESS", "DELETE_COMPLETE"]}).stack_summaries
          inactiveStacks.each do |stack|
            if stack.stack_name == stack_name
              stacks = @cfn.list_stack_resources(stack_name: stack.stack_id).stack_resource_summaries
              stack_name = stack.stack_id
              break
            end
          end
        end

        stacks.each do |event|
          puts "#{event.logical_resource_id} - #{event.resource_status}"
        end
        master = @cfn.describe_stacks(stack_name: stack_name).stacks[0]
        case master.stack_status
          when 'CREATE_IN_PROGRESS'
            puts "stack #{stack_name} creation in-progress"
          when 'UPDATE_IN_PROGRESS'
            puts "stack #{stack_name} update in-progress"
          when 'DELETE_IN_PROGRESS'
            puts "stack #{stack_name} deletion in-progress"
          when 'ROLLBACK_IN_PROGRESS', 'UPDATE_ROLLBACK_IN_PROGRESS'
            puts "stack #{stack_name} rollback in-progress"
          when 'CREATE_COMPLETE'
            puts "stack #{stack_name} creation complete"
          when 'UPDATE_COMPLETE'
            puts "stack #{stack_name} update complete"
          when 'DELETE_COMPLETE'
            puts "stack #{stack_name} deletion complete"
          when 'CREATE_FAILED'
            puts "stack #{stack_name} creation failed"
          when 'ROLLBACK_COMPLETE', 'UPDATE_ROLLBACK_COMPLETE'
            puts "stack #{stack_name} rolled back"
          when 'ROLLBACK_FAILED', 'UPDATE_ROLLBACK_FAILED'
            puts "stack #{stack_name} rollback failed"
          when 'DELETE_FAILED'
            puts "stack #{stack_name} deletion failed"
        end
        completed, success = stack_update_complete(master)
        sleep 10 unless completed
      end
      if success
        puts "SUCCESS: Environment #{stack_name} #{master.stack_status.downcase.tr('_',' ')}"
      else
        abort "ERROR: Environment #{stack_name} #{master.stack_status.downcase.tr('_',' ')}"
      end
    end

    def stack_update_complete( stack )
      success_states = ["CREATE_COMPLETE", "UPDATE_COMPLETE", "DELETE_COMPLETE"]
      failure_states = ["CREATE_FAILED", "DELETE_FAILED", "ROLLBACK_COMPLETE", "ROLLBACK_FAILED", "UPDATE_ROLLBACK_COMPLETE", "UPDATE_ROLLBACK_FAILED"]

      if success_states.include?(stack.stack_status)
          return [true, true]
      elsif failure_states.include?(stack.stack_status)
          return [true, false]
      end

      return false
    end

  end
end
