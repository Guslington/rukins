require 'aws-sdk'

module Rukins
  module Vpc
    class << self

      def vpc_exists(client,stack_name)
        resp = client.describe_vpcs({
          filters: [{name: "tag:Name",values: ["#{stack_name}"],},],
        })
        return (resp.vpcs.any? ? true : false)
      end

      def describe_vpc(client,stack_name)
        resp = client.describe_vpcs({
          filters: [{name: "tag:Name",values: ["#{stack_name}"],},],
        })
        return resp.vpcs[0]
      end

      def peer_exists(requester_client,requester_vpc_id,accepter_vpc_id)
        resp = client.describe_vpc_peering_connections({
          filters: [
            {name: "requester-vpc-info.vpc-id", values: ["#{requester_vpc_id}"]},
            {name: "accepter-vpc-info.vpc-id", values: ["#{accepter_vpc_id}"]}
          ]
        })
        return (peering_connections.vpc_peering_connections.any? ? true : false)
      end

      def create_peer(requester_client,requester_vpc_id,accepter_vpc_id,peer_with_account)
        resp = requester_client.create_vpc_peering_connection({
          vpc_id: requester_vpc_id,
          peer_vpc_id: accepter_vpc_id,
          peer_owner_id: peer_with_account,
        })
        puts "INFO: peering connection created, #{resp.vpc_peering_connection.vpc_peering_connection_id}"
        return resp.vpc_peering_connection.vpc_peering_connection_id
      end

      def wait_for_peer(stack_client,peer_id)
        begin
          started_at = Time.now
          stack_client.wait_until(:vpc_peering_connection_exists, vpc_peering_connection_ids: [peer_id]) do |w|
            w.max_attempts = nil
            w.before_wait do |attempts, response|
              puts "INFO: waiting for peering connection..."
              throw :failure if Time.now - started_at > 3600
            end
          end
        rescue => e
          abort "ERROR: Failed to wait for the peering connection to be created, #{e}"
        end
      end

      def accept_peer(stack_client,peer_id)
        resp = stack_client.accept_vpc_peering_connection({
          vpc_peering_connection_id: "#{peer_id}",
        })
        puts "INFO: Peering connection accepted"
      end

      def tag_peer(client,peer_id,requester,accepter)
        client.create_tags({
          resources: ["#{peer_id}"],
          tags: [{key: "Name",value: "#{requester}-to-#{accepter}"}]
        })
        puts "INFO: Tagging peering connection"
      end

      def create_route(client,route_table_id,cidr,peer_id)
        client.create_route({
          route_table_id: route_table_id,
          destination_cidr_block: ciinabox_vpc_cidr,
          vpc_peering_connection_id: peer_id,
        })
        puts "INFO: added #{cidr} to route table #{route_table_id}"
      end

      def delete_routes(client,route_table_id,cidr)
        client.delete_route({
          route_table_id: route_table_id,
          destination_cidr_block: stack_vpc_cidr,
        })
        puts "INFO: #{cidr} route removed from route table #{route_table_id}"
      end

    end
  end
end