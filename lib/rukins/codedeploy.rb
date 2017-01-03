require 'aws-sdk'
require 'rukins/core/credentials'
require 'rukins/core/utils'

module Rukins
  class Codedeploy

    def initialize(options)
      @options = options
      @config = Rukins::Utils.load_default_params
      credentials = Rukins::Credentials.new(@options)
      @s3 = Aws::S3::Client.new(credentials.value)
      @codedeploy = Aws::CodeDeploy::Client.new(credentials.value)
    end

    def run
      abort "TODO"
      compress
      put_zip_to_s3
      deployment_id = deploy
      wait(deployment_id) if @options.wait
    end

    def compress
      puts "TODO"
    end

    def put_zip_to_s3
      puts "TODO"
    end

    def deploy
      resp = @codedeploy.create_deployment({
        application_name: @options.application,
        deployment_group_name: @options.deployment_group,
        revision: {
          revision_type: "S3",
          s3_location: {
            bucket: @config['source_bucket'],
            key: "codedeploy/#{@options.application}/#{@options.version}/deploy.zip",
            bundle_type: "zip",
          }
        }
      })
      puts "INFO: Deployed #{@codedeploy.application} ID: #{resp.deployment_id}"
      return resp.deployment_id
    end

    def wait(deployment_id)
      begin
        started_at = Time.now
        @codedeploy.wait_until(:deployment_successful, deployment_id: deployment_id) do |w|
          w.max_attempts = nil
          w.before_wait do |attempts, response|
            throw :failure if Time.now - started_at > 3600
          end
        end
      rescue Aws::Waiters::Errors::WaiterFailed
        abort "ERROR"
      end
    end

  end
end
