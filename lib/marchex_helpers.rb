require_relative 'kitchen'

module MarchexHelpers
  autoload :Kitchen, 'kitchen'
  def self.kitchen(**options)
    # Alias in a top-level namespace to reduce typing.
    @instance = Kitchen.new(**options)
    @instance.to_yaml
  end
end