require 'aws-sdk'
require 'rukins/core/credentials'
require 'rukins/core/utils'

module Rukins
  class NsRecord

    def initialize(options)
      @options = options
      @config  = Rukins::Utils.load_default_params

      credentials = Rukins::Credentials.new(@options)
      @stack_client = Aws::Route53::Client.new(credentials.value)

      root_options = Hash.new
      if @options.has_key?(:root_zone_account)
        root_options.merge!(account:  @options.root_zone_account)
        root_options.merge!(region:   @options.region)
        root_options.merge!(profile:  @options.root_zone_profile) if @options.root_zone_profile
        root_options.merge!(role:     @options.root_zone_role)    if @options.root_zone_role
      else
        root_options = @options
      end

      credentials  = Rukins::Credentials.new(root_options)
      @root_client = Aws::Route53::Client.new(credentials.value)
    end

    def run
      root_zone  = @config['dns_domain'].to_s
      stack_zone = "#{@options.stack_name}.#{@config['dns_domain']}"
      abort "ERROR: #{root_zone} or #{stack_zone} can't be found found" if !zone_exists(root_zone) || !zone_exists(stack_zone)
      stack_zone_id = get_zone_id(stack_zone)
      name_servers = get_name_servers(stack_zone_id)
      root_zone_id = get_zone_id(root_zone)
      begin
        change_ns_record(root_zone_id,name_servers,stack_zone,"CREATE")
      rescue Aws::Route53::Errors::InvalidChangeBatch
        change_ns_record(root_zone_id,name_servers,stack_zone,"UPSERT")
      end
    end

    def zone_exists(zone)
      puts "INFO: Searching for #{zone}"
      resp = @root_client.list_hosted_zones_by_name({
        dns_name: zone,
      })
      return (resp.hosted_zones.any? ? true : false)
    end

    def get_zone_id(zone)
      resp = @root_client.list_hosted_zones_by_name({
        dns_name: zone,
        max_items: 1
      })
      puts "ZONE ID: #{resp.hosted_zones[0].id}" if @options.verbose
      return resp.hosted_zones[0].id
    end

    def change_ns_record(zone_id,name_servers,zone,action)
      @root_client.change_resource_record_sets({
        hosted_zone_id: zone_id,
        change_batch: {
          comment: "#{zone} NS records",
          changes: [
            {
              action: action,
              resource_record_set: {
                name: zone,
                type: "NS",
                ttl: 300,
                resource_records: [
                  { value: name_servers[0] },
                  { value: name_servers[1] },
                  { value: name_servers[2] },
                  { value: name_servers[3] }
                ]
              },
            },
          ],
        },
      })
      puts "INFO: NS record #{action.downcase} for #{zone}" if @options.verbose
    end

    def get_name_servers(zone_id)
      resp = @stack_client.get_hosted_zone({id: zone_id})
      puts "NAME SERVERS: #{resp.delegation_set.name_servers}" if @options.verbose
      return resp.delegation_set.name_servers
    end

  end
end
