require 'aws-sdk'
require 'rukins/aws/kms'
require 'rukins/core/credentials'
require 'rukins/core/utils'

module Rukins
  class SecretsCreate

    def initialize(options)
      @options = options
      @config  = Rukins::Utils.load_default_params
      
      @ops_account_id = @config['accounts']['ops']
      @stack_account_id = @config['accounts'][@options.account]

      credentails = Rukins::Credentials.new(options)
      @s3_client  = Aws::S3::Client.new(credentials.value)
      @kms_client = Aws::KMS::Client.new(credentials.value) 
    end

    def run
      if !Rukins::Kms.alias_exists(@kms_client,@options.stack_name)
        key_id = Rukins::Kms.create_key(@kms_client,@options.stack_name,@ops_account_id,@stack_account_id)
        Rukins::Kms.create_alias(@kms_client,key_id,@options.stack_name)
      else
        puts "INFO: found key alias/#{@options.stack_name}"
      end

      puts "INFO: Encrypting and putting secrets into s3"
      bucket = "#{@config['secrets']['store'][@options.account]['bucket']}"
      @options[:keys].each_pair do |key,secret|
        path = "#{@config['secrets']['store'][@options.account]['key']}/#{@options.stack_name}/#{key}"
        if !Rukins::Kms.secret_exist(@s3_client,bucket,path)
          blob = Rukins::Kms.encrypt(@kms_client,secret,@options.stack_name)
          Rukins::Kms.put_secret(@s3_client,blob,bucket,path)
          puts "    #{key} complete"
        else
          puts "    #{key} already exists"
        end
      end
      
    end

  end
end