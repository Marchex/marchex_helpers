#Custom Foodcritic rules copied from Etsy https://github.com/etsy/foodcritic-rules
@coreservices = ['dropcamel']
@corecommands = ['apt-get', 'git', 'mkdir', 'useradd', 'usermod', 'touch', 'yum']

# This rule does not detect execute resources defined inside a conditional, as foodcritic rule FC023 (Prefer conditional attributes)
# already provides this. It's recommended to use both rules in conjunction. (foodcritic -t etsy,FC023)
rule 'ETSY004', 'Execute resource defined without conditional or action :nothing' do
  tags %w{style recipe etsy marchex marchex_base}
  recipe do |ast,filename|
    find_resources(ast, :type => 'execute').find_all do |cmd|
      cmd_actions = (resource_attribute(cmd, 'action') || resource_name(cmd)).to_s
      condition = Nokogiri::XML(cmd.to_xml).xpath('//ident[@value="only_if" or @value="not_if" or @value="creates"][parent::fcall or parent::command or ancestor::if]')
      (condition.empty? && !cmd_actions.include?('nothing'))
    end.map{|cmd| match(cmd)}
  end
end

rule 'ETSY005', 'Action :restart sent to a core service' do
  tags %w{style recipe etsy marchex marchex_base}
  recipe do |ast, filename|
    find_resources(ast).select do |resource|
      notifications(resource).any? do |notification|
        @coreservices.include?(notification[:resource_name]) and
          notification[:action] == :restart
      end
    end
  end
end

rule 'ETSY006', 'Execute resource used to run chef-provided command' do
  tags %w{style recipe etsy marchex marchex_base}
  recipe do |ast|
    find_resources(ast, :type => 'execute').find_all do |cmd|
      cmd_str = (resource_attribute(cmd, 'command') || resource_name(cmd)).to_s
      @corecommands.any? { |corecommand| cmd_str.include? corecommand }
    end.map{|c| match(c)}
  end
end
