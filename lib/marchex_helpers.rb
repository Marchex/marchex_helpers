
module MarchexHelpers
  autoload :Kitchen, 'marchex_helpers/kitchen'
  autoload :Helpers, 'marchex_helpers/helpers'

  def self.kitchen(**options)
    # Alias in a top-level namespace to reduce typing.
    MarchexHelpers::Kitchen.kitchen(**options)
  end
end