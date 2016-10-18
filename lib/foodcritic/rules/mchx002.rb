rule 'MCHX002', 'array value set without set_array_attribute method in environment/role cookbook attributes file' do
  tags %w{style marchex marchex_role marchex_environment correctness}
  cookbook do |path|
    attributes_file = File.join(path, 'attributes', 'default.rb')
    if File.exists?(attributes_file)
      lines = File.readlines(attributes_file)
      lines.collect.with_index do |line, index|
        # Find cases of arrays being set without set_array_attribute
        if (line.match('node\.') &&
            !line.match('package_set') && # ignore package_set attributes; they're designed to be appended
            ( line.match('=\s+%w') ||
              line.match('Array') ||
              line.match('=\s+\[') ||
              line.match('to_a')
            )
           )
          {
            :filename => attributes_file,
            :matched => attributes_file,
            :line => index + 1,
            :column => 0
          }
        end
      end.compact
    else
      [ file_match(attributes_file) ]
    end
  end
end
