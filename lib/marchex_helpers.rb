require 'yaml'

class MarchexHelpers
  def self.kitchen_yaml(**options)
    yaml = {}

    platforms = {
      vagrant: {
        'ubuntu-16.04-pristine' => {
          box:      'opscode-ubuntu-16.04',
          box_url:  'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-16.04_chef-provisionerless.box'
        },
        'ubuntu-12.04-pristine' => {
          box:      'opscode-ubuntu-12.04',
          box_url:  'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box'
        },
        'ubuntu-12.04-mchx' => {
          box:      'u12-04-04032015',
          box_url:  'http://tools1.sad.marchex.com:8898/vm_images/u12-04-04032015.box'
        },
        'centos-6.6' => {
          box:      'opscode-centos-6.6',
          box_url:  'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.6_chef-provisionerless.box'
        }
      },
      ec2: {
        'ubuntu-12.04' => {
          image_id: 'ami-86688bb5'
        }
      }
    }

    chef_versions = options[:chef_versions] || ['12.6.0', 'latest']

    if options[:driver] == 'ec2'
      yaml['driver'] = {
        'name'            => 'ec2',
        'aws_ssh_key_id'  => (options[:ec2_aws_ssh_key_id] || 'tools-team'),
        'region'          => (options[:ec2_region]         || 'us-west-2'),
        'subnet_id'       => (options[:ec2_subnet_id]      || 'subnet-2a251342'),
        'instance_type'   => (options[:ec2_instance_type]  || 't2.micro'),
        'tags'  => {
          'Name'    => '<%= ENV["KITCHEN_INSTANCE_NAME"] || "test kitchen instance" %>',
          'team'    => 'Tools',
          'project' => 'test-kitchen'
        }
      }

      my_platforms = options[:platforms] || platforms[:ec2].keys

    else
      yaml['driver'] = {'name' => 'vagrant'}

      my_platforms = options[:platforms] || platforms[:vagrant].keys

    end


    yaml['provisioner'] = {
      'name'                          => 'chef_zero',
      'chef_omnibus_install_options'  => '-d /tmp/vagrant-cache/vagrant_omnibus'
    }

    yaml['platforms'] = []
    chef_versions.each do |chef_version|
      my_platforms.each do |my_platform|
        platform = {}
        if yaml['driver']['name'] == 'ec2'
          platform = {
            'name'          => my_platform + '-' + chef_version,
            'driver'        => { 'image_id' => platforms[:ec2][my_platform][:image_id] },
            'driver_config' => {
              'provision'             => true,
              'require_chef_omnibus'  => chef_version
            }
          }
        else
          platform = {
            'name'          => my_platform + '-' + chef_version,
            'driver_config' => {
              'box'                   => platforms[:vagrant][my_platform][:box],
              'box_url'               => platforms[:vagrant][my_platform][:box_url],
              'provision'             => true,
              'require_chef_omnibus'  => chef_version,
              'vagrantfiles'          => [
                'test/shared/vagrant_cache_omnibus.rb'
              ]
            }
          }
        end
        yaml['platforms'].push(platform)
      end
    end
    # chomping beginning of yaml so that it's needed in local yamls
    # ( CodeRange does it )
    yaml.to_yaml.gsub(/---[ \n]/, '')
  end
end

