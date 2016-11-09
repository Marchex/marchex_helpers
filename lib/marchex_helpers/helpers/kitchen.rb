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
                :username => 'ec2-user'
            }
          },
          'centos-7.2-pristine' => {
            image_id: 'ami-d2c924b2',
            :transport => {
                :username => 'centos'
            }
          }
        }
      }

      @@platform_tags = {
        :vagrant => {
          :supported => ['ubuntu-12.04-mchx','ubuntu-16.04-pristine','centos-7.2'],
          :all =>       @@platforms[:vagrant].keys
        },
        :ec2 => {
          :supported => ['ubuntu-12.04-mchx','ubuntu-16.04-pristine','centos-7.2-pristine'],
          :all =>       @@platforms[:ec2].keys
        }
      }

      @@provisioner = {
          'name'                          => 'chef_zero',
          'chef_omnibus_install_options'  => '-d /tmp/vagrant-cache/vagrant_omnibus',
          'attributes'                    => {
              'chef_client'                 => {
                'config'                      => {
                    'chef_server_url'           => 'http://localhost:8889'
                }
              }
          }
      }
      #
      #
      #
      def initialize(**args)
        defaults = {
          :driver             => 'vagrant',
          :chef_versions      => ['12.6.0', 'latest'],
          :ec2_aws_ssh_key_id => 'tools-team',
          :ec2_region         => 'us-west-2',
          :ec2_instance_type  => 't2.micro',
          :ec2_subnet_id      => 'subnet-2a251342',
          :ec2_ssh_key        => ENV['KITCHEN_EC2_SSH_KEY_PATH'],
          :ec2_username       => 'ubuntu',
          :ec2_timeout        => 10,
          :ec2_tag_Name       => (ENV['KITCHEN_INSTANCE_NAME'] || 'test kitchen instance'),
          :ec2_tag_team       => 'Tools',
          :ec2_tag_project    => 'test-kitchen',
          :ec2_tag_creator    => ENV['USER'] || 'delivery',
          :platforms          => nil # keys from @@platforms become defaults
        }
        @args = defaults.merge(args)

        if @args[:platforms] == nil || @args[:platforms].length == 0
          abort_platforms "No 'platforms' supplied"
        end
      end
      #
      #
      #
      def to_yaml
        yaml = {}
        yaml['provisioner'] = @@provisioner
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
        # If no platforms, get all entries for the drive
        list = args[:platforms] || @@platforms[:"#{args[:driver]}"].keys

        #
        # Step 1: Convert platform_tags into platforms.
        list.each do |plat|
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
              data['driver']['transport'] ={}
              data['driver']['transport']['username'] = @@platforms[:ec2][platform][:transport][:username]

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

