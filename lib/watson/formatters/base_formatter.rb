module Watson::Formatters
  class BaseFormatter
    include Watson

    def initialize(config)
      @config = config
    end
  end
end
