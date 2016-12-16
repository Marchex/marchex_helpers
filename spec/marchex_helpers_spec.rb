require 'spec_helper'
require_relative '../lib/marchex_helpers'
require 'psych'
require 'climate_control'

describe 'MarchexHelpers' do
  before (:example) do
    @args = {
        driver: :ec2,
        ec2_aws_ssh_key_id: 'my_awesome_key',
        ec2_region: 'us_awesome_1',
        ec2_instance_type: 't2.awesome',
        ec2_subnet_id: 'subnet-awesome',
        platforms: [:all],
        chef_versions: ['12.6.0', 'latest']
    }
  end

  it 'returns valid yaml' do
    result = MarchexHelpers.kitchen(platforms: [:supported])
    expect{ result }.to_not raise_error
  end
  #
  # platform tests
  it 'contains 5 platforms for vagrant latest' do
    result = MarchexHelpers.kitchen(driver: :vagrant, chef_versions: ['latest'], platforms: [:all])
    expect( Psych.load(result)['platforms'].count.to_i ).to eq(5)
  end

  it 'contains 4 platforms for ec2 latest' do
    result = MarchexHelpers.kitchen(driver: :ec2, chef_versions: ['latest'], platforms: [:supported])
    expect( Psych.load(result)['platforms'].count.to_i ).to eq(4)
  end

  it 'contains 2 platform entries for ec2 with a single platform' do
    result = MarchexHelpers.kitchen(driver: :ec2, platforms: ['ubuntu-12.04-mchx'])
    expect( Psych.load(result)['platforms'].count.to_i ).to eq(2)
  end

  # provisioner tests
  %w( vagrant ec2 ).each do |drv|
    it "Sets the correct chef_server_url attribute for the #{drv} driver" do
      result = MarchexHelpers.kitchen(driver: drv.to_sym, chef_versions: ['latest'], platforms: [:all])
      expect( Psych.load(result)['provisioner']['attributes']['chef_client']['config']['chef_server_url'] ).to eq('http://localhost:8889')
    end

    it "Sets the correct environments_path attribute for the #{drv} driver" do
      result = MarchexHelpers.kitchen(driver: drv.to_sym, chef_versions: ['latest'], platforms: [:all])
      expect( Psych.load(result)['provisioner']['environments_path'] ).to eq('test/environments')
    end
  end

  it 'Sets the correct set_fqdn attribute for vagrant VMs' do
    result = MarchexHelpers.kitchen(driver: :vagrant)
    expect( Psych.load(result)['provisioner']['attributes']['set_fqdn'] ).to eq('cxcp99.sad.marchex.com')
  end

  it 'Sets the correct set_fqdn attribute for ec2 VMs' do
    result = MarchexHelpers.kitchen(driver: :ec2)
    expect( Psych.load(result)['provisioner']['attributes']['set_fqdn'] ).to eq('cxcp99.aws-us-west-2-vpc2.marchex.com')
  end

  it 'returns 4 platforms for ec2 calling get_selected_platforms directly' do
    instance = MarchexHelpers::Helpers::Kitchen.new(@args)
    result = instance.validate_platforms(@args)
    expect( result.count.to_i ).to eq(4)
  end

  it 'catches an invalid platform symbol and throws an error' do
    @args[:platforms] = [:error]
    expect {
      instance = MarchexHelpers::Helpers::Kitchen.new(@args)
      instance.validate_platforms(@args)
    }.to raise_error(RuntimeError)
  end

  it 'catches an invalid platform label and throws an error' do
    @args[:platforms] = ['error']
    expect {
      instance = MarchexHelpers::Helpers::Kitchen.new(@args)
      instance.get_platforms(@args)
    }.to raise_error(RuntimeError)
  end

  it 'gets all the platforms if no :platforms specified' do
    result = MarchexHelpers.kitchen(driver: :ec2)
    expect( Psych.load(result)['platforms'].count.to_i ).to eq(8)
  end
  #
  # transport tests
  it 'contains default username ubuntu for ec2 driver and mchx-ubuntu ami' do
    plat = 'ubuntu-12.04-mchx'
    ver = '12.6.0'
    name = plat + '-' + ver
    result = MarchexHelpers.kitchen( driver: :ec2, chef_version: [ver], platforms: [plat] )
    plat_result = (Psych.load(result)['platforms'].select{ |i| i['name'] == name }).pop
    expect( plat_result['transport']['username']).to eq('ubuntu')
  end

  it 'contains default username ec2-user for ec2 driver and default ubuntu ami' do
    plat = 'ubuntu-16.04-pristine'
    ver = '12.6.0'
    name = plat + '-' + ver
    result = MarchexHelpers.kitchen( driver: :ec2, platforms: [plat] )
    plat_result = (Psych.load(result)['platforms'].select{ |i| i['name'] == name }).pop
    expect( plat_result['transport']['username']).to eq('ubuntu')
  end

  it 'contains default username ubuntu for ec2 driver and default centos ami' do
    plat = 'centos-7.2-pristine'
    ver = '12.6.0'
    name = plat + '-' + ver
    result = MarchexHelpers.kitchen( driver: :ec2, platforms: [plat] )
    plat_result = (Psych.load(result)['platforms'].select{ |i| i['name'] == name }).pop
    expect( plat_result['transport']['username']).to eq('centos')
  end

  it 'contains default ssh_key path for ec2 driver' do
    ClimateControl.modify KITCHEN_EC2_SSH_KEY_PATH: '/foo/bar/a_special_key' do
      result = MarchexHelpers.kitchen( driver: :ec2, platforms: [:all] )
      expect( Psych.load(result)['transport']['ssh_key']).to eq('/foo/bar/a_special_key')
    end
  end
  #
  # default tag tests
  it 'adds USER to the creator tag if it exists' do
    ClimateControl.modify USER: 'llloyd' do
      result = MarchexHelpers.kitchen( driver: :ec2, platforms: [:all] )
      expect( Psych.load(result)['driver']['tags']['creator']).to eq('llloyd')
      expect( Psych.load(result)['driver']['tags']['Name']).to match(/-llloyd$/)
    end
  end

  it 'adds delivery to the creator tag if USER does not exist' do
    ClimateControl.modify USER: nil do
      result = MarchexHelpers.kitchen( driver: :ec2, platforms: [:all] )
      expect( Psych.load(result)['driver']['tags']['creator']).to eq('delivery')
      expect( Psych.load(result)['driver']['tags']['Name']).to match(/-delivery$/)
    end
  end

  it 'passes ec2 parameters correctly' do
    yaml = MarchexHelpers.kitchen(@args)
    result = Psych.load(yaml)
    expect( result['driver']['tags'].count.to_i ).to eq(4)
    expect( result['driver']['aws_ssh_key_id'] ).to eq('my_awesome_key')
    expect( result['driver']['region'] ).to eq('us_awesome_1')
    expect( result['driver']['instance_type'] ).to eq('t2.awesome')
    expect( result['driver']['subnet_id'] ).to eq('subnet-awesome')
    expect( result['driver']['user_data'] ).to match(/ ec2 create-tags /)
  end
end
