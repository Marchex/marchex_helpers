require 'marchex_helpers'

module MarchexHelpers
  module Kitchen
    def self.instance
      @instance
    end

    def self.kitchen(**options)
      @instance = MarchexHelpers::Helpers::Kitchen.new(**options)
      @instance.to_yaml
    end
  end
end