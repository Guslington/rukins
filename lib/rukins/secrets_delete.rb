require 'aws-sdk'
require 'rukins/aws/kms'
require 'rukins/core/utils'
require 'rukins/core/credentials'

module Rukins
  class SecretsDelete

    def initialize(options)
      @options = options
      @config  = Rukins::Utils.load_default_params

      credentails = Rukins::Credentials.new(options)
      @s3_client  = Aws::S3::Client.new(credentials.value)
      @kms_client = Aws::KMS::Client.new(credentials.value) 
    end

    def run
      puts "INFO: Deleting keys from s3"
      abort "ERROR: alias/#{options.stack_name} doesn't exist" if !@kms.alias_exists(@kms_client,@options.stack_name)
      bucket = "#{@config['secrets']['store'][@options.account]['bucket']}"
      @options[:keys].each do |key|
        path = "#{@config['secrets']['store'][@options.account]['key']}/#{@options.stack_name}/#{key}"
        if @kms.secret_exist(@s3_client,bucket,path)
          @kms.delete_key(@s3_client,bucket,path)
          puts "    #{key} deleted"
        else
          puts "    #{key} doesn't exist"
        end
      end
    end

  end
end