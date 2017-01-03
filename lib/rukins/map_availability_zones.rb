require 'aws-sdk'
require 'rukins/core/credentials'
require 'rukins/core/utils'

module Rukins
  class MapAvailabilityZones

    def initialize(options)
      @options = options
      @config  = Rukins::Utils.load_default_params
      @az_config_file = 'config/az.yml'
    end

    def run
      credentials = Rukins::Credentials.new(@options)
      ec2 = Aws::EC2::Client.new(credentials.value)
      region_resp = ec2.describe_regions()

      account = @config['accounts'][@options['account']]
      mapping = Hash.new
      mapping["mapped_availability_zones"] = Hash.new
      mapping["mapped_availability_zones"][account] = Hash.new

      new_options = @options.dup

      region_resp.regions.each do |region|
        new_options.merge!(region: region.region_name)
        credentials = Rukins::Credentials.new(new_options)
        ec2region = Aws::EC2::Client.new(credentials.value)

        mapping['mapped_availability_zones'][account][region.region_name] = Hash.new
        @config['maximum_availability_zones'].times do |i|
          mapping['mapped_availability_zones'][account][region.region_name][i] = false
        end

        az_resp = ec2region.describe_availability_zones()
        puts "INFO: Adding mapping for #{region.region_name}"
        az_resp.availability_zones.each_with_index do |az,i|
          mapping['mapped_availability_zones'][account][region.region_name][i] = az.zone_name
        end

        if File.file?(@az_config_file)
          puts "INFO: Adding new mappings to existing #{@az_config_file}"
          existing_mapping= YAML::load(File.open(@az_config_file).read)
          new_mapping = Hash.new
          new_mapping['mapped_availability_zones'] = existing_mapping['mapped_availability_zones'].merge(mapping['mapped_availability_zones'])
        else
          puts "INFO: No mapping #{@az_config_file} found, creating new one."
          new_mapping = mapping
        end

        File.open(@az_config_file, 'w') {|f| f.write new_mapping.to_yaml }

      end
    end

  end
end
