rule 'MCHX001', 'TODO: not updated in README.md' do
  tags %w{docs marchex marchex_base}
  cookbook do |path|
    readme = File.join(path, 'README.md')
    if File.exists?(readme)
      lines = File.readlines(readme)
      lines.collect.with_index do |line, index|
        if line.match('TODO')
          {
            :filename => readme,
            :matched => readme,
            :line => index + 1,
            :column => 0
          }
        end
      end.compact
    else
      [ file_match(readme) ]
    end
  end
end

