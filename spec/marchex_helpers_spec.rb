require 'spec_helper'
require_relative '../lib/marchex_helpers'
require 'psych'

describe 'MarchexHelpers' do
  before (:context) do
  end

  it 'returns valid yaml'do
    result = MarchexHelpers.kitchen
    expect{ Psych.safe_load(result) }.to_not raise_error
  end

  # This assumes knowledge of the default data available
  it 'contains 4 platforms for vagrant latest' do
    result = MarchexHelpers.kitchen(driver: 'vagrant', chef_versions: ['latest'])
    expect( Psych.safe_load(result)['platforms'].count.to_i ).to eq(4)
  end

  it 'contains 1 platform for ec2 latest' do
    result = MarchexHelpers.kitchen(driver: 'ec2', chef_versions: ['latest'])
    expect( Psych.safe_load(result)['platforms'].count.to_i ).to eq(1)
  end

  it 'contains 2 entries platform for ec2 latest with an aws key name' do
    result = MarchexHelpers.kitchen(driver: 'ec2', platforms: ['ubuntu-12.04-mchx'])
    expect( Psych.safe_load(result)['platforms'].count.to_i ).to eq(2)
  end

  it 'contains default username \'ubuntu\' for ec2 driver' do
    result = MarchexHelpers.kitchen( driver: 'ec2' )
    expect( Psych.safe_load(result)['transport']['username']).to eq('ubuntu')
  end

  it 'passes ec2 parameters correctly' do
    result = MarchexHelpers.kitchen(
        driver: 'ec2',
        ec2_aws_ssh_key_id: 'my_awesome_key',
        ec2_region: 'us_awesome_1',
        ec2_instance_type: 't2.awesome',
        ec2_subnet_id: 'subnet-awesome'
    )
    expect( Psych.safe_load(result)['driver']['tags'].count.to_i ).to eq(3)
    expect( Psych.safe_load(result)['driver']['aws_ssh_key_id'] ).to eq('my_awesome_key')
    expect( Psych.safe_load(result)['driver']['region'] ).to eq('us_awesome_1')
    expect( Psych.safe_load(result)['driver']['instance_type'] ).to eq('t2.awesome')
    expect( Psych.safe_load(result)['driver']['subnet_id'] ).to eq('subnet-awesome')
  end
end