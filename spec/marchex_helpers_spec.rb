require 'spec_helper'
require_relative '../lib/marchex_helpers'
require 'psych'
require 'climate_control'

describe 'MarchexHelpers' do
  before (:context) do
  end

  it 'returns valid yaml'do
    result = MarchexHelpers.kitchen(driver: :vagrant, platforms: [:supported])
    expect{ result }.to_not raise_error
  end

  # This assumes knowledge of the default data available
  it 'contains 4 platforms for vagrant latest' do
    result = MarchexHelpers.kitchen(driver: :vagrant, chef_versions: ['latest'], platforms: [:all])
    expect( Psych.load(result)['platforms'].count.to_i ).to eq(4)
  end

  it 'contains 1 platform for ec2 latest' do
    result = MarchexHelpers.kitchen(driver: :ec2, chef_versions: ['latest'], platforms: [:supported])
    expect( Psych.load(result)['platforms'].count.to_i ).to eq(1)
  end

  it 'contains 2 entries platform for ec2 latest with an aws key name' do
    result = MarchexHelpers.kitchen(driver: :ec2, platforms: ['ubuntu-12.04-mchx'])
    expect( Psych.load(result)['platforms'].count.to_i ).to eq(2)
  end

  it 'contains default username \'ubuntu\' for ec2 driver' do
    result = MarchexHelpers.kitchen( driver: :ec2, platforms: [:all] )
    expect( Psych.load(result)['transport']['username']).to eq('ubuntu')
  end

  it 'contains default ssh_key path for ec2 driver' do
    ClimateControl.modify KITCHEN_EC2_SSH_KEY_PATH: '/foo/bar/a_special_key' do
      result = MarchexHelpers.kitchen( driver: :ec2, platforms: [:all] )
      expect( Psych.load(result)['transport']['ssh_key']).to eq('/foo/bar/a_special_key')
    end
  end

  it 'adds USER to the creator tag if it exists' do
    ClimateControl.modify USER: 'llloyd' do
      result = MarchexHelpers.kitchen( driver: :ec2, platforms: [:all] )
      expect( Psych.load(result)['driver']['tags']['creator']).to eq('llloyd')
    end
  end

  it 'passes ec2 parameters correctly' do
    yaml = MarchexHelpers.kitchen(
        driver: :ec2,
        ec2_aws_ssh_key_id: 'my_awesome_key',
        ec2_region: 'us_awesome_1',
        ec2_instance_type: 't2.awesome',
        ec2_subnet_id: 'subnet-awesome',
        platforms: [:all]
    )
    result = Psych.load(yaml)
    expect( result['driver']['tags'].count.to_i ).to eq(4)
    expect( result['driver']['aws_ssh_key_id'] ).to eq('my_awesome_key')
    expect( result['driver']['region'] ).to eq('us_awesome_1')
    expect( result['driver']['instance_type'] ).to eq('t2.awesome')
    expect( result['driver']['subnet_id'] ).to eq('subnet-awesome')
  end
end
