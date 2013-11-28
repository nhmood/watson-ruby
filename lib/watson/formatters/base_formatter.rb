module Watson::Formatters
  class BaseFormatter
    include ::Watson
    DEBUG = false

    def initialize(config)
      @config = config
    end
  end
end
