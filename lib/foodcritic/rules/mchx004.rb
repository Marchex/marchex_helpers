rule 'MCHX004', 'precedence level other than normal used in role cookbook attributes file' do
  tags %w{style marchex marchex_role correctness}
  cookbook do |path|
    attributes_file = File.join(path, 'attributes', 'default.rb')
    if File.exists?(attributes_file)
      lines = File.readlines(attributes_file)
      lines.collect.with_index do |line, index|
        if (line.match('node\.') || line.match('set_array_attribute')) && ! line.match('normal')
          {
            :filename => attributes_file,
            :matched => attributes_file,
            :line => index + 1,
            :column => 0
          }
        end
      else
        [ file_match(attributes_file) ]
      end
    end.compact
  end
end
