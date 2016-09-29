require_relative 'kitchen'

module MarchexHelpers

  def self.kitchen(**options)
    # Alias in a top-level namespace to reduce typing.
    @instance = MarchexHelpers::Kitchen.new(**options)
    @instance.to_yaml
  end
end