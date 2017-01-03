require 'aws-sdk'
require 'rukins/core/credentials'
require 'rukins/core/utils'

module Rukins
  class Create

    def initialize(options)
      @options = options
      @config  = Rukins::Utils.load_default_params
      credentials = Rukins::Credentials.new(@options)
      @cfn = Aws::CloudFormation::Client.new(credentials.value)
    end

    def run
      cfn_options = create_cfn_options
      create(cfn_options)
      wait if @options.wait
    end

    def create_cfn_options
      parameters = []
      if @options[:parameters]
        @options[:parameters].each_pair do |key,value|
          parameters << {parameter_key: key, parameter_value: value}
        end
      end

      cfn_options = {
        stack_name: @options.stack_name,
        template_url: "https://#{@config['source_bucket']}.s3.amazonaws.com/cloudformation/#{@config['application_name']}/#{@options.cf_version}/master.json",
        capabilities: ["CAPABILITY_IAM"],
        on_failure: "ROLLBACK",
        tags: [{key: "Name", value: @options.stack_name}]
      }
      cfn_options.merge!(parameters: parameters) if parameters.any?

      puts "PARAMETERS: #{parameters}" if @options.verbose && parameters.any?
      puts "INFO: Creating cloudfromation stack #{@options.stack_name}"
      return cfn_options
    end

    def create(cfn_options)
      begin
        resp = @cfn.create_stack(cfn_options)
        puts "STACK_ID: #{resp.stack_id}"
      rescue => e
        abort "ERROR: #{e.class} #{e}"
      end
    end

    def wait
      begin
        started_at = Time.now
        @cfn.wait_until(:stack_create_complete, stack_name: @options.stack_name) do |w|
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
