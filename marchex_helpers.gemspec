Gem::Specification.new do |s|
  s.name        = 'marchex_helpers'
  s.version     = '0.1.18'
  s.date        = '2016-11-08'
  s.summary     = 'Helpers to inject Marchex standard Chef bits'
  s.description = ""
  s.authors     = ['Tools Team']
  s.email       = 'tools-team@marchex.com'
  s.files       = `git ls-files`.split($/)
  s.license     = 'Apache-2.0'
  s.require_paths = %w{lib}
end
