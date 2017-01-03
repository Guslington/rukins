require 'aws-sdk'
require 'rukins/core/credentials'
require 'rukins/core/utils'

module Rukins
  class Deploy

    def initialize(options)
      @options = options
      @config  = Rukins::Utils.load_default_params
    end

    def run
      credentials = Rukins::Credentials.new(@options)
      s3 = Aws::S3::Client.new(credentials.value)
      Dir.glob("output/**/*.json") do |file|
        template = File.open(file, 'rb')
        filename = file.gsub("output/", "")
        bucket   = @config['source_bucket']
        path     = "cloudformation/#{@config['application_name']}/#{@options.cf_version}/#{filename}"
        s3.put_object({body: template, bucket: bucket, key: path})
        puts "INFO: Copied #{file} to s3://#{bucket}/#{path}"
      end
    end
    
  end
end