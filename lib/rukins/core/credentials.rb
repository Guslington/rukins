require 'aws-sdk'
require 'rukins/core/utils'

module Rukins
  class Credentials
    attr_accessor :value

    def initialize(options)
      @options = options
      @config  = Rukins::Utils.load_default_params
      raise 'No region set' if !@options.region
      if options.profile
        profile
      elsif options.role
        role
      else
        local
      end
    end

    private

    def profile
      credentials = Aws::SharedCredentials.new(profile_name: @options.profile)
      @value = {region: @options.region, credentials: credentials}
      puts "INFO: using profile #{@options.profile}" if @options.verbose
    end

    def role
      raise 'No Aws account specified' if !@options.account
      credentials = Aws::AssumeRoleCredentials.new(
        role_arn: "arn:aws:iam::#{@config[@options.account]}:role/#{@options.role}", 
        role_session_name: "#{get_host_name}-#{get_date}", 
        region: @options.region
      )
      @value = {region: @options.region, credentials: credentials}
      puts "INFO: Using role #{@options.role}" if @options.verbose
    end

    def local
      @value = {region: @options.region}
      puts "INFO: Using local credentials" if @options.verbose
    end

  end
end