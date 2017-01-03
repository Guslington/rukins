require 'aws-sdk'

module Rukins
  module Kms
    class << self
    
      def alias_exists(client,stack_name)
        resp = client.list_aliases({limit: 100})
        resp.aliases.include?("alias/#{stack_name}") ? true : false
      end

      def create_key(client,stack_name,ops_account_id,stack_account_id)
        policy = {
          policy: {
            Version: "2012-10-17",
            Statement: [
              {
                Sid: "Enable IAM User Permissions",
                Effect: "Allow",
                Principal: {
                  AWS: [
                    "arn:aws:iam::#{ops_account_id}:root"
                  ]
                },
                Action: "kms:*",
                Resource: "*"
              },
              {
                Sid: "Allow access for Key Administrators",
                Effect: "Allow",
                Principal: {
                  AWS: [
                    "arn:aws:iam::#{}:root"
                  ]
                },
                Action: [
                  "kms:Create*",
                  "kms:Describe*",
                  "kms:Enable*",
                  "kms:List*",
                  "kms:Put*",
                  "kms:Update*",
                  "kms:Revoke*",
                  "kms:Disable*",
                  "kms:Get*",
                  "kms:Delete*",
                  "kms:ScheduleKeyDeletion",
                  "kms:CancelKeyDeletion"
                ],
                Resource: "*"
              },
              {
                Sid: "Allow use of the key",
                Effect: "Allow",
                Principal: {
                  AWS: "arn:aws:iam::#{@config['accounts'][@options[:account]]}:root"
                },
                Action: [
                  "kms:Decrypt",
                  "kms:DescribeKey"
                ],
                Resource: "*"
              }
            ]
          }
        }
        
        begin
          resp = client.create_key({
            policy: JSON.pretty_generate(policy),
            description: stack_name,
            key_usage: "ENCRYPT_DECRYPT",
          })
          puts "INFO: #{stack_name} key created"
        rescue => e
          abort "ERROR: #{e}"
        end

        return resp.key_metadata.key_id
      end

      def create_alias(client,key_id,stack_name)
        begin
          client.create_alias({
            alias_name: "alias/#{stack_name}",
            target_key_id: key_id
          })
          puts "INFO: alias/#{stack_name} created"
        rescue => e
          abort "ERROR: #{e}"
        end
      end  

      def secret_exist(client,bucket,path)
        resp = client.list_objects({
          bucket: bucket,
          prefix: path,
        })
        return (resp.contents.any? ? false : true)
      end

      def encrypt(client,secret,stack_name)
        resp = client.encrypt({
          key_id: "alias/#{stack_name}",
          plaintext: secret,
        })
        return Base64.encode64(resp.ciphertext_blob)
      end

      def put_secret(client,blob,bucket,path)
        client.put_object({
          acl: "private", 
          body: blob,
          bucket: bucket,
          key: path,
          server_side_encryption: "AES256",
        })
      end

      def delete_key(client,bucket,path)
        client.delete_object({
          bucket: bucket,
          key: path,
        })      
      end

    end
  end
end