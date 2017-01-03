require 'aws-sdk'
require 'rukins/core/credentials'
require 'rukins/core/utils'
require 'rukins/aws/vpc'

module Rukins
  class CreateVpcPeer

    def initialize(options)
      @options = options
      @config  = Rukins::Utils.load_default_params

      credentails = Rukins::Credentials.new(@options)
      @stack_client = Aws::Route53::Client.new(credentials.value)

      requester_options = Hash.new
      if @options.has_key?(:requester_account)
        requester_options.merge!(account:  @options.requester_account)
        requester_options.merge!(region:   @options.region)
        requester_options.merge!(profile:  @options.requester_profile) if @options.requester_profile
        requester_options.merge!(role:     @options.requester_role)    if @options.requester_role
      else
        requester_options = @options
      end

      credentials  = Rukins::Credentials.new(requester_options)
      @requester_client = Aws::Route53::Client.new(credentials.value)
    end

    def run
      abort "ERROR: #{@options.stack_name} vpc doesn't exist" if !Rukins::Vpc.vpc_exists(@stack_client,@options.stack_name)
      stack_vpc = Rukins::Vpc.describe_vpc(@stack_client,@options.stack_name)
      stack_vpc_id = stack_vpc.vpc_id
      stack_vpc_cidr = stack_vpc.cidr_block
      
      abort "ERROR: #{@options[:requester_stack]} vpc doesn't exist" if !Rukins::Vpc.vpc_exists(@requester_client,@options.requester_stack)
      requester_vpc = Rukins::Vpc.describe_vpc(@requester_client,@options.requester_stack)
      requester_vpc_id = requester_vpc.vpc_id
      requester_vpc_cidr = requester_vpc.cidr_block

      abort "ERROR: Peering connection already exists" if Rukins::Vpc.peer_exists(@requester_client,requester_vpc_id,stack_vpc_id)
      peer_id = Rukins::Vpc.create_peer(@requester_client,requester_vpc_id,stack_vpc_id,@options.account)
      Rukins::Vpc.wait_for_peer(@stack_client,peer_id)
      Rukins::Vpc.accept_peer(@stack_client,peer_id)
      Rukins::Vpc.tag_peer(@stack_client,peer_id,@options.requester_stack,@options.stack_name)

      puts "INFO: Setting up routes for #{@options.stack_name}"
      resp = @stack_client.describe_route_tables({filters: [{name:"vpc-id",values:[stack_vpc_id]}]})
      resp.route_tables.each { |rt| create_route(@stack_client,rt.route_table_id,requester_cidr,peer_id)}

      puts "INFO: Setting up routes for #{@options.requester_stack}"
      resp = @requester_client.describe_route_tables({filters: [{name:"vpc-id",values:[requester_vpc_id]}]})
      resp.route_tables.each { |rt| create_route(@requester_client,rt.route_table_id,requester_cidr,peer_id)}
    end
    
  end
end