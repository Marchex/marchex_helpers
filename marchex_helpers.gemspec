Gem::Specification.new do |s|
  s.name        = 'marchex_helpers'
  s.version     = '0.1.28'
  s.date        = '2017-04-11'
  s.summary     = 'Helpers to inject Marchex standard Chef bits'
  s.description = ''
  s.authors     = ['Tools Team']
  s.email       = 'tools-team@marchex.com'
  s.files       = `git ls-files`.split($/)
  s.license     = 'Apache-2.0'
  s.require_paths = %w{lib}
end
