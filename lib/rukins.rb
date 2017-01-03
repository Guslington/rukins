require 'thor'

require "rukins/version"
require "rukins/generate"
require "rukins/validate"
require "rukins/deploy"
require "rukins/create"
require "rukins/delete"
require "rukins/update"
require "rukins/wait"
require "rukins/ns_record"
require "rukins/map_availability_zones"
require "rukins/create_vpc_peer"
require "rukins/delete_vpc_peer"
require "rukins/new"
require "rukins/secrets_delete"
require "rukins/secrets_create"
require "rukins/list"
require "rukins/codedeploy"

module Rukins
  class Commands < Thor

    map %w[--version -v] => :__print_version
    desc "--version, -v", "print the version"
    def __print_version
      puts Rukins::VERSION
    end

    class_option :verbose,
      aliases: :V,
      type: :boolean,
      default: false,
      lazy_default: true,
      desc: "Extra logging"

    class_option :wait,
      group: :aws,
      aliases: :w,
      type: :boolean,
      default: false,
      lazy_default: true,
      desc: "wait for aws task completion"

    class_option :region,
      group: :aws,
      aliases: :r,
      type: :string,
      desc: "AWS Region"

    class_option :account,
      group: :aws,
      aliases: :a,
      type: :string,
      desc: "Aws account name e.g. ops/dev/prod"

    class_option :role,
      group: :aws,
      aliases: :R,
      type: :string,
      desc: "Aws IAM Role name to assume"

    class_option :profile,
      group: :aws,
      aliases: :p,
      type: :string,
      desc: "Profile name in Aws credentials file"

    desc "list", "List all cloudfromation stacks in an aws account/region"
    long_desc <<-LONG
    List all cloudfromation stacks in an aws account for a specific region
    LONG
    def list
      task = Rukins::List.new(options)
      task.run
    end

    desc "generate", "Generate templates with cfndsl"
    long_desc <<-LONG
    Generates JSON templates from ruby templates with cfndsl and output to the output/ directory.
    LONG
    method_option :cf_version, aliases: :v, type: :string, default: 'dev', desc: "Version number of the templates"
    method_option :pretty, aliases: :p, type: :boolean, default: false, lazy_default: true, desc: "Pretifies the JSON output"
    def generate
      task = Rukins::Generate.new(options)
      task.run
    end

    desc "validate", "Validate templates"
    long_desc <<-LONG
    Validates the JSON template in the output directory against AWS and will return any errors.
    LONG
    def validate
      task = Rukins::Validate.new(options)
      task.run
    end

    desc "deploy", "deploy templates to S3"
    long_desc <<-LONG
    Deploy the JSON templates in the output directory to the S3 bucket defined in the default_params.yml.
    LONG
    method_option :cf_version, aliases: :v, type: :string, default: 'dev', desc: "Version number of the templates"
    def deploy
      task = Rukins::Deploy.new(options)
      task.run
    end

    desc "create", "create cloudformation stack"
    long_desc <<-LONG
    Creates a cloudformation stack
    EnvironmentName:${ENVIRONMENT_NAME} parameter required as it is used as the stack name
    LONG
    method_option :stack_name, required: true, aliases: :s, type: :string, desc: "Name of the cloudformation stack and the environment name parameter"
    method_option :cf_version, aliases: :v, type: :string, default: 'dev', desc: "Version number of the templates"
    method_option :parameters, aliases: :P, type: :hash, desc: "Parameters required by the cloudfromation template, -p EnvironmentName:dev EnvironmentType:dev"
    def create
      task = Rukins::Create.new(options)
      task.run
    end

    desc "update", "update cloudformation stack"
    long_desc <<-LONG
    Updates a cloudformation stack
    LONG
    method_option :stack_name, required: true, aliases: :s, type: :string, desc: "Name of the cloudformation stack"
    method_option :cf_version, aliases: :v, type: :string, default: 'dev', desc: "Version number of the templates"
    method_option :use_previous_template, aliases: :u, type: :boolean, default: false, lazy_default: true, desc: "use current template"
    method_option :parameters, aliases: :P, type: :hash, desc: "Parameters required by the cloudfromation template, -p EnvironmentName:dev EnvironmentType:dev"
    def update
      task = Rukins::Update.new(options)
      task.run
    end

    desc "delete", "delete cloudfromation stack"
    long_desc <<-LONG
    Deletes a cloudformation stack
    LONG
    method_option :stack_name, required: true, aliases: :s, type: :string, desc: "Name of the cloudformation stack"
    def delete
      task = Rukins::Delete.new(options)
      task.run
    end

    desc "ns-record", "Creates/Updates NS record for a cloudformation stack"
    long_desc <<-LONG
    Creates or Updates a Name Server record for a cloudfromation stack
    If `root_zone_account` is not specified `account`, `role` and `profile` is used for the root zone account
    LONG
    method_option :stack_name, required: true, aliases: :s, type: :string, desc: "Name of the cloudformation stack"
    method_option :root_zone_account, aliases: :ra, type: :string, desc: "Aws account of root dns zone"
    method_option :root_zone_profile, aliases: :rp, type: :string, desc: "Profile name of the root zone Aws account in Aws credentials file"
    method_option :root_zone_role, aliases: :rr, type: :string, desc: "Aws IAM Role name to assume in the root zone Aws account"
    def ns_record
      task = Rukins::NsRecord.new(options)
      task.run
    end

    desc "map-availability-zones", "Generate mapping of all az's for an account"
    long_desc <<-LONG
    Generate mapping of all availability zones for an Aws account
    LONG
    def map_availability_zones
      require_class_options(options,['account','region'])
      task = Rukins::MapAvailabilityZones.new(options)
      task.run
    end

    desc "create-secrets", "Create secrets"
    long_desc <<-LONG
    Create secrets
    LONG
    method_option :keys, required: true, aliases: :k, type: :hash, desc: "Hash of keys to create -k key1:secret key2:secret"
    method_option :stack_name, required: true, aliases: :s, type: :string, desc: "Cloudformation stack name"
    def create_secrets
      task = Rukins::SecretsCreate.new(options)
      task.run
    end

    desc "delete-secrets", "Delete secrets"
    long_desc <<-LONG
    Delete secrets
    LONG
    method_option :keys, required: true, aliases: :k, type: :array, desc: "array of key names -k key1 key2 key3"
    method_option :stack_name, required: true, aliases: :s, type: :string, desc: "Cloudformation stack name"
    def delete_secrets
      task = Rukins::SecretsDelete.new(options)
      task.run
    end


    desc "create-vpc-peer", "Create VPC peer connection between 2 VPCs"
    long_desc <<-LONG
    Create a VPC peering connection between 2 VPCs. Can be in the same or seperate Aws accounts
    Matches a VPC Name tag againest the `requester_stack` in the `requester_account`
    If `requester_account` is not specified `account`, `role` and `profile` is used for the requester stack
    LONG
    method_option :stack_name, required: true, aliases: :s, type: :string, desc: "Cloudformation stack name"
    method_option :requester_stack, required: true, aliases: :rs, type: :string, desc: "The stack you want to peer with"
    method_option :requester_account, aliases: :ra, type: :string, desc: "The account the stack to want to peer with is in"
    method_option :requester_role, aliases: :rr, type: :string, desc: "The role to assume in the requester account"
    method_option :requester_profile, aliases: :rp, type: :string, desc: "The profile to use for the requester account"
    def create_vpc_peer
      task = Rukins::CreateVpcPeer.new(options)
      task.run
    end

    desc "delete-vpc-peer", "Delete VPC peer connection between 2 VPCs"
    long_desc <<-LONG
    Delete a VPC peering connection between 2 VPCs. Can be in different or sepatate Aws accounts
    LONG
    method_option :stack_name, required: true, aliases: :s, type: :string, desc: "Cloudformation stack name"
    method_option :requester_stack, required: true, aliases: :rs, type: :string, desc: "The stack you want to peer with"
    method_option :requester_account, aliases: :ra, type: :string, desc: "The account the stack to want to peer with is in"
    method_option :requester_role, aliases: :rr, type: :string, desc: "The role to assume in the requester account"
    method_option :requester_profile, aliases: :rp, type: :string, desc: "The profile to use for the requester account"
    def delete_vpc_peer
      task = Rukins::DeleteVpcPeer.new(options)
      task.run
    end

    desc "codedeploy", "Codedeploy"
    long_desc <<-LONG
    Codedeploy
    LONG
    method_option :application, required: true, aliases: :A, type: :string, desc: ""
    method_option :deployment_group, required: true, aliases: :G, type: :string, desc: ""
    method_option :version, required: true, aliases: :v, type: :string, desc: ""
    def codedeploy
      task = Rukins::Codedeploy.new(options)
      task.run
    end

    desc "wait", "Wait for rukins tasks to complete"
    long_desc <<-LONG
    Wait for cloudformation update, create, delete and codedeploy tasks to complete and output status messages
    LONG
    method_option :stack_name, required: true, aliases: :s, type: :string, desc: "cloudformation stack name"
    def wait
      task = Rukins::Wait.new(options)
      task.run
    end

    desc "new [project]", "Create new cloudfromation project"
    long_desc <<-LONG
    Creates a new cloudfromation project with folder structure and config files.
    LONG
    method_option :git, aliases: :g, type: :boolean, default: true, desc: "Initialize project with git"
    method_option :ops_account, aliases: :ops, type: :string, default: '111111111111', desc: "Aws account id of the operations account"
    method_option :dev_account, aliases: :dev, type: :string, default: '111111111111', desc: "Aws account id of the development account"
    method_option :prod_account, aliases: :prod, type: :string, default: '111111111111', desc: "Aws account id of the production account"
    method_option :root_dns_zone, aliases: :d, type: :string, default: 'example.com', desc: "Root DNS zone"
    method_option :source_bucket, aliases: :s, type: :string, default: 'source.example.com', desc: "source s3 bucket name"
    def new(project)
      task = Rukins::New.new(project,options)
      task.run
    end

    private

    def require_class_options(options,required = [])
      not_supplied = []
      required.each do |r|
        not_supplied << r.prepend('--').gsub('_','-') if !options[r]
      end
      abort "No value provided for required options '#{not_supplied.join('\' \'')}'" if not_supplied.any?
    end

  end
end
