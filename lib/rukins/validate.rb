require 'aws-sdk'
require 'rukins/core/credentials'
require 'rukins/core/utils'

module Rukins
  class Validate

    def initialize(options)
      @options = options
      @config  = Rukins::Utils.load_default_params
    end

    def run
      credentials = Rukins::Credentials.new(@options)
      cfn = Aws::CloudFormation::Client.new(credentials.value)
      s3  = Aws::S3::Client.new(credentials.value)

      failed_templates = []
      Dir.glob("output/**/*.json") do |file|
        template = File.open(file, 'rb')
        filename = file.gsub("output/", "")   
        s3.put_object({
          body: template,
          bucket: @config['source_bucket'],
          key: "cloudformation/#{@config['application_name']}/validate/#{filename}",
        })
        template_url = "https://#{@config['source_bucket']}.s3.amazonaws.com/cloudformation/#{@config['application_name']}/validate/#{filename}"
        puts "INFO: Validating #{filename}" if @options.verbose
        begin
          resp = cfn.validate_template({template_url: template_url})
          puts "SUCCESS: #{filename} validated" if @options.verbose
        rescue => e
          puts "FAILED: [#{filename}] #{e}"
          failed_templates << filename
        end
      end
      abort "ERROR: #{failed_templates.count} failed validation" if failed_templates.any?
      puts "FINISHED: #{Dir["output/**/*.json"].count} templates validated successfully"
    end
    
  end
end