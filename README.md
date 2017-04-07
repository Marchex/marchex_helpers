# marchex_helpers
A rubygem for injecting standard helpers into in-house Chef cookbooks

## MarchexHelpers.kitchen
Supplies standard sections of a .kitchen.yml that work in the Marchex environment. 

```
defaults = {
    :driver             => 'vagrant',
    :chef_versions      => ['12.6.0', 'latest'],
    :ec2_aws_ssh_key_id => 'tools-team',
    :ec2_region         => 'us-west-2',
    :ec2_instance_type  => 't2.micro',
    :ec2_subnet_id      => 'subnet-2a251342',
    :ec2_ssh_key        => ENV["KITCHEN_EC2_SSH_KEY_PATH"],
    :ec2_username       => 'ubuntu',
    :ec2_timeout        => 10,
    :platforms          => nil # keys from @@platforms become defaults
}
```
See the [code](https://github.marchex.com/marchex-chef/marchex_helpers/blob/master/lib/marchex_helpers/helpers/kitchen.rb#L6) for the current platforms.  Note that platforms are required.

.kitchen.yml example:
```
---
#<% require 'marchex_helpers' %>
<%= MarchexHelpers.kitchen( platforms: ['ubuntu-12.04-mchx'] ) %>
```
.kitchen.ec2.yml example:
```
---
#<% require 'marchex_helpers' %>
<%= MarchexHelpers.kitchen( driver: 'ec2', ec2_aws_ssh_key_id: 'tools-team', platforms: [:supported] ) %>
```

## Development

### Tests
rake unit
```
jcarter-mac:marchex_helpers jcarter$ rake unit
bundle check || bundle install
The Gemfile's dependencies are satisfied
bundle exec rspec spec
.....................

Finished in 0.05647 seconds (files took 0.09975 seconds to load)
21 examples, 0 failures
```

### Build

$ rake build
```
jcarter-mac:marchex_helpers jcarter$ rake build marchex_helpers.gemspec
WARNING:  no homepage specified
WARNING:  See http://guides.rubygems.org/specification-reference/ for help
  Successfully built RubyGem
  Name: marchex_helpers
  Version: 0.1.26
  File: marchex_helpers-0.1.26.gem
```

Then upload to http://rubygems.sea.marchex.com/


## Copyright and license

Code and documentation copyright 2016-2017 [Marchex, Inc.](https://www.marchex.com/) ([GitHub](https://github.com/Marchex)). Code released under the [MIT License](https://github.com/Marchex/marchex_helpers/blob/master/LICENSE.txt).
