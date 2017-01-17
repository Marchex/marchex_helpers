require 'yaml'

module MarchexHelpers
  module Helpers
    class Kitchen
      @@platforms = {
        :vagrant => {
          'ubuntu-16.04-pristine' => {
            :box =>      'opscode-ubuntu-16.04',
            :box_url =>  'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-16.04_chef-provisionerless.box'
          },
          'ubuntu-12.04-pristine' => {
            :box =>     'opscode-ubuntu-12.04',
            :box_url => 'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box'
          },
          'ubuntu-12.04-mchx' => {
            :box   =>   'u12-04-04032015',
            :box_url => 'http://tools1.sad.marchex.com:8898/vm_images/u12-04-04032015.box'
          },
          'centos-6.6' => {
            :box =>     'opscode-centos-6.6',
            :box_url => 'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.6_chef-provisionerless.box'
          },
          'centos-7.2' => {
            :box =>     'opscode-centos-7.2',
            :box_url => 'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-7.2_chef-provisionerless.box'
          }
        },
        :ec2 => {
          'ubuntu-12.04-mchx' => {
            image_id: 'ami-86688bb5',
            :transport => {
                :username => 'ubuntu'
            }
          },
          'ubuntu-16.04-pristine' => {
            image_id: 'ami-746aba14',
            :transport => {
                :username => 'ubuntu'
            }
          },
          'centos-6.7-pristine' => {
              image_id: 'ami-fe3d9e9e',
              :transport => {
                  :username => 'centos'
              }
          },
          'centos-7.2-pristine' => {
            image_id: 'ami-fd01a29d',
            :transport => {
                :username => 'centos'
            }
          }
        }
      }

      @@platform_tags = {
        :vagrant => {
          :supported => ['ubuntu-12.04-mchx','ubuntu-16.04-pristine','centos-6.6','centos-7.2'],
          :supported_kvms => ['ubuntu-16.04-pristine','centos-6.6', 'centos-7.2'],
          :supported_vms => ['ubuntu-12.04-mchx','ubuntu-16.04-pristine'],
          :all =>       @@platforms[:vagrant].keys
        },
        :ec2 => {
          :supported => ['ubuntu-12.04-mchx','ubuntu-16.04-pristine','centos-6.7-pristine','centos-7.2-pristine'],
          :supported_kvms => ['ubuntu-16.04-pristine', 'centos-6.7-pristine', 'centos-7.2-pristine'],
          :supported_vms => ['ubuntu-12.04-mchx','ubuntu-16.04-pristine'],
          :all =>       @@platforms[:ec2].keys
        }
      }

      #
      #
      #
      def initialize(**args)
        defaults = {
          :driver             => 'vagrant',
          :chef_versions      => ['12.6.0', 'latest'],
          :fqdn               => 'cxcp99.sad.marchex.com',
          :ec2_fqdn           => 'cxcp99.aws-us-west-2-vpc2.marchex.com',
          :ec2_aws_ssh_key_id => 'tools-team',
          :ec2_region         => 'us-west-2',
          :ec2_instance_type  => 't2.micro',
          :ec2_subnet_id      => 'subnet-2a251342',
          :ec2_ssh_key        => ENV['KITCHEN_EC2_SSH_KEY_PATH'],
          :ec2_username       => 'ubuntu',
          :ec2_timeout        => 10,
          :ec2_tag_Name       => (ENV['KITCHEN_INSTANCE_NAME'] || 'test-kitchen-local-' + ENV['USER']),
          :ec2_tag_team       => 'Tools',
          :ec2_tag_project    => 'test-kitchen',
          :ec2_tag_creator    => ENV['USER'] || 'delivery',
          :platforms          => nil
        }

        @args = defaults.merge(args)

        if @args[:platforms] == nil || @args[:platforms].length == 0
          @args[:platforms] = @@platform_tags[:"#{args[:driver]}"][:all]
        end
      end
      #
      #
      #
      def to_yaml
        yaml = {}
        yaml['provisioner'] = get_provisioner @args
        yaml['driver'] = get_drivers @args
        yaml['platforms'] = get_platforms @args
        yaml['transport'] = get_transports @args if @args[:driver] == :ec2 #only needed for EC2 at this time

        # chomping beginning of yaml so that it's needed in local yamls
        # ( CodeRanger does it )
        result = yaml.to_yaml.gsub(/^---[ \n]/, '')
        File.open('/tmp/MarchexHelpers.kitchen_yaml.out', 'w') {|f| f.write(result) }
        result
      end
      #
      #
      #
      def validate_platforms(**args)
        result = []
        bad_platforms = []
        #
        # Step 1: Convert platform_tags into platforms.
        args[:platforms].each do |plat|
          #
          # If a Symbol, then it's a tag representing 1 or more platforms;
          # get the actual platforms from @@platform_tags
          if plat.is_a?(Symbol)
            if @@platform_tags[:"#{args[:driver]}"][:"#{plat}"].nil?
              abort_platforms "Platform tag :#{plat} not found"
            end
            result.concat(@@platform_tags[:"#{args[:driver]}"][:"#{plat}"])
            next
          end
          #
          # If a String, just add it
          if plat.is_a?(String)
            result.push(plat)
            next
          end
          #
          # If we get here, you prolly passed an array or a hash.
          abort_platforms "Platform tag #{plat} neither Symbol, nor String. Aborting."
        end

        #
        # Step 2: Make sure the platforms are valid, abort if invalid
        result.uniq.each do |platform|
          if @@platforms[:"#{args[:driver]}"][platform].nil?
            bad_platforms.push(platform)
          end
        end

        if bad_platforms.length > 0
          abort_platforms "Platforms '#{bad_platforms.join("', '")}' not found"
        end

        # return results
        result
      end
      #
      #
      #
      def get_platforms(**args)
        # all validation logic moved to validate_platforms...
        my_platforms = validate_platforms(args)
        result = []
        my_platforms.uniq.each do |platform|
          args[:chef_versions].uniq.each do |version|
            data = {}
            data['name'] = platform + '-' + version
            data['driver_config'] = {}
            data['driver_config']['provision'] = true
            data['driver_config']['require_chef_omnibus']  = version
            if args[:driver] == :ec2
              data['driver'] = {} if data['driver'].nil?
              data['driver']['image_id']  = @@platforms[:ec2][platform][:image_id]
              # haven't found a more elegant way to map these values -- passing in hashes from
              # the @@platforms structure leads to yaml keys with two colons (e.g. :username:)
              data['transport'] ={}
              data['transport']['username'] = @@platforms[:ec2][platform][:transport][:username]

            else
              data['driver_config']['box']          = @@platforms[:vagrant][platform][:box]
              data['driver_config']['box_url']      = @@platforms[:vagrant][platform][:box_url]
              data['driver_config']['vagrantfiles'] = [
                  'test/shared/vagrant_cache_omnibus.rb'
              ]
            end
            result.push(data)
          end
        end
        result
      end
      #
      #
      #
      def get_drivers(**args)

        result = {}
        result['name'] = args[:driver].to_s
        if args[:driver] == :ec2
          result['aws_ssh_key_id']  = args[:ec2_aws_ssh_key_id]
          result['region']          = args[:ec2_region]
          result['subnet_id']       = args[:ec2_subnet_id]
          result['instance_type']   = args[:ec2_instance_type]
          result['tags']            = {}
          result['tags']['Name']    = args[:ec2_tag_Name]
          result['tags']['team']    = args[:ec2_tag_team]
          result['tags']['project'] = args[:ec2_tag_project]
          result['tags']['creator'] = args[:ec2_tag_creator]
          result['user_data'] = <<-EOH
#!/bin/bash -e
# this script has been tested with our kitchen images for ubuntu 12.04 and 16.04,
# and centos 6.7 and 7.2.  it installs the aws tools, then updates the tags
# for the created volumes.

export PATH="/usr/local/bin:$PATH"

apt-get -y install awscli || apt-get -y install unzip curl || yum -y install aws-cli || yum -y install unzip curl

if [[ -z "$(which aws)" ]]; then
  curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
  unzip awscli-bundle.zip
  ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
fi

AWS=$( which aws )

mkdir -p ~/.aws
cat > ~/.aws/credentials <<EOL
[default]
aws_access_key_id = XXX
aws_secret_access_key = YYY
EOL

AWS_INSTANCE_ID=$( curl http://169.254.169.254/latest/meta-data/instance-id )
ROOT_DISK_ID=$( ${AWS} ec2 describe-volumes --region #{args[:ec2_region]} --filter "Name=attachment.instance-id, Values=${AWS_INSTANCE_ID}" --query "Volumes[].VolumeId" --out text )

${AWS} ec2 create-tags --region #{args[:ec2_region]} --resources ${ROOT_DISK_ID} --tags Key=Name,Value=#{args[:ec2_tag_Name]}:root Key=team,Value=#{args[:ec2_tag_team]} Key=project,Value=#{args[:ec2_tag_project]} Key=creator,Value=#{args[:ec2_tag_creator]}
EOH
        end
        result
      end
      #
      #
      def get_transports(**args)
        result = {}
        if args[:driver] == :ec2
          result['ssh_key'] = args[:ec2_ssh_key]
          #result['username'] = args[:ec2_username]
          result['connection_timeout'] = args[:connection_timeout]
        end
        result
      end
      #
      #
      #
      def get_provisioner(**args)
        result = {}
        result['name'] = 'chef_zero'
        result['chef_omnibus_install_options'] = '-d /tmp/vagrant-cache/vagrant_omnibus'
        result['attributes'] = {
          'set_fqdn'              => args[:fqdn],
          'chef_client'           => {
            'config'              => {
              'chef_server_url' => 'http://localhost:8889'
            }
          }
        }
        if args[:driver] == :ec2
          result['attributes']['set_fqdn'] = args[:ec2_fqdn]
        end
        result
      end

      def abort_platforms(msg)
        errstring = "#{msg}.\n" +
          "For #{@args[:driver]}, possible platforms are:\n" +
          "  #{@@platforms[ :"#{@args[:driver]}" ].keys.sort.join(', ')}\n" +
          "and possible platform tags are:\n" +
          "  :#{@@platform_tags[ :"#{@args[:driver]}" ].keys.sort.join(', :')}"
        raise errstring
      end
    end
  end
end

