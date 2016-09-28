require 'spec_helper'

describe 'MarchexHelpers' do
  before (:context) do
  end

  it 'returns valid yaml'do
    result = MarchexHelpers.kitchen_yaml
    expect{ Psych.safe_load(result) }.to_not raise_error
  end

  # This assumes knowledge of the default data available
  it 'contains 4 platforms for vagrant latest' do
    result = MarchexHelpers.kitchen_yaml(driver: 'vagrant', chef_versions: ['latest'])
    expect( Psych.safe_load(result)['platforms'].count.to_i ).to eq(4)
  end

  it 'contains 1 platform for ec2 latest' do
    result = MarchexHelpers.kitchen_yaml(driver: 'ec2', chef_versions: ['latest'])
    expect( Psych.safe_load(result)['platforms'].count.to_i ).to eq(1)
  end

end