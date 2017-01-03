require 'aws-sdk'
require 'rukins/core/utils'
require 'rukins/core/credentials'

module Rukins
  class List

    def initialize(options)
      @options = options
      @config = Rukins::Utils.load_default_params
      credentials = Rukins::Credentials.new(@options)
      @cfn = Aws::CloudFormation::Client.new(credentials.value)
    end

    def run
      resp = @cfn.describe_stacks()
      resp.stacks.each do |stack|
        puts "STACK: #{stack.stack_name} STATUS: #{stack.stack_status}"
      end
    end

  end
end
