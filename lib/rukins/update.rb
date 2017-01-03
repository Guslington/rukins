require 'aws-sdk'
require 'rukins/core/credentials'
require 'rukins/core/utils'

module Rukins
  class Update

    def initialize(options)
      @options = options
      @config  = Rukins::Utils.load_default_params
      credentials = Rukins::Credentials.new(@options)
      @cfn = Aws::CloudFormation::Client.new(credentials.value)
    end

    def run
      current_parameters = get_current_parameters
      updated_parameters = update_parameters(current_parameters)
      cfn_options = create_cfn_options(updated_parameters)
      update(cfn_options)
      wait if @options.wait
    end

    def update(cfn_options)
      begin
        resp = @cfn.update_stack(cfn_options)
        puts "INFO: Updated stack #{@options.stack_name}"
        puts "STACK ID: #{resp.stack_id}"
      rescue => e
        abort "ERROR: #{e.class} #{e}"
      end
    end

    def create_cfn_options(parameters)
      cfn_options = {
        stack_name: @options.stack_name,
        capabilities: ["CAPABILITY_IAM"],
      }
      cfn_options.merge!(parameters: parameters) if parameters.any?
      @options.use_previous_template \
        ? cfn_options.merge!(use_previous_template: @options.use_previous_template) \
        : cfn_options.merge!(template_url: "https://#{@config['source_bucket']}.s3.amazonaws.com/cloudformation/#{@config['application_name']}/#{@options['cf_version']}/master.json")
      puts "INFO: #{cfn_options}" if @options.verbose
      return cfn_options
    end

    def update_parameters(current_parameters)
      parameters = []
      current_parameters.each_pair do |key,value|
        if @options.parameters && @options.parameters.key?(key) && value != @options.parameters[key]
          parameters << {parameter_key: key, parameter_value: @options.parameters[key]}
        else
          parameters << {parameter_key: key, use_previous_value: true}
        end
      end
      puts "INFO: Updated parameters\n#{parameters}" if @options.verbose
      return parameters
    end

    def get_current_parameters
      stack = @cfn.describe_stacks({stack_name: @options.stack_name}).stacks[0]
      current_parameters = {}
      stack.parameters.each do |parameter|
        current_parameters.merge!(parameter.parameter_key => parameter.parameter_value)
      end
      puts "INFO: Current parameters\n#{current_parameters}" if @options.verbose
      return current_parameters
    end

    def wait
      begin
        started_at = Time.now
        @cfn.wait_until(:stack_update_complete, stack_name: @options.stack_name) do |w|
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
