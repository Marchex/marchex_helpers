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
              }
          },
          :ec2 => {
              'ubuntu-12.04-mchx' => {
                  image_id: 'ami-86688bb5'
              }
          }
      }

      @@provisioner = {
          'name'                          => 'chef_zero',
          'chef_omnibus_install_options'  => '-d /tmp/vagrant-cache/vagrant_omnibus'
      }

      @@tags = {
          'name'    => '<%= ENV["KITCHEN_INSTANCE_NAME"] || "test kitchen instance" %>',
          'team'    => 'Tools',
          'project' => 'test-kitchen'
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
            :ec2_ssh_key        => "<%= ENV['KITCHEN_EC2_SSH_KEY_PATH'] %>",
            :ec2_username       => 'ubuntu',
            :ec2_timeout        => 10,
            :platforms          => nil # keys from @@platforms become defaults
        }
        @args = defaults.merge(args)
      end
      #
      #
      #
      def to_yaml
        yaml = {}
        yaml['provisioner'] = @@provisioner
        yaml['driver'] = get_drivers @args
        yaml['platforms'] = get_platforms @args
        yaml['transport'] = get_transports @args if @args[:driver] = 'ec2' #only needed for EC2 at this time

        # chomping beginning of yaml so that it's needed in local yamls
        # ( CodeRanger does it )
        result = yaml.to_yaml.gsub(/^---[ \n]/, '')
        File.open('/tmp/MarchexHelpers.kitchen_yaml.out', 'w') {|f| f.write(result) }
        result
      end
      #
      #
      #
      def get_platforms(**args)
        my_platforms = args[:platforms] || @@platforms[:"#{args[:driver]}"].keys
        result = []
        args[:chef_versions].each do |version|
          my_platforms.each do |platform|
            data = {}
            data['name'] = platform + '-' + version
            data['driver_config'] = {}
            data['driver_config']['provision'] = true
            data['driver_config']['require_chef_omnibus']  = version
            if args[:driver] == 'ec2'
              data['driver'] = { 'image_id' => @@platforms[:ec2][platform][:image_id] }
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
        result['name'] = args[:driver]
        if args[:driver] == 'ec2'
          result['aws_ssh_key_id']  = args[:ec2_aws_ssh_key_id]
          result['region']          = args[:ec2_region]
          result['subnet_id']       = args[:ec2_subnet_id]
          result['instance_type']   = args[:ec2_instance_type]
          result['tags']            = @@tags
        end
        result
      end
      #
      #
      def get_transports(**args)
        result = {}
        result['name'] = args[:driver]
        if args[:driver] == 'ec2'
          result['ssh_key'] = args[:ec2_ssh_key]
          result['username'] = args[:ec2_username]
          result['connection_timeout'] = args[:connection_timeout]
        end
      end
    end
  end
end

