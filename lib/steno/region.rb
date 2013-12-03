module Steno
  class Region
    attr_accessor :name
    attr_accessor :code
    attr_accessor :council

    def initialize(hash={})
      (hash || {}).each_pair { |k, v| self.send("#{k}=", v) }
    end

    REGIONS = [
      Region.new(name: 'Cape Town', code: 'cape-town', council: 'Cape Town City Council'),
    ]

    def self.for_code(code)
      REGIONS.find { |r| r.code == code }
    end
  end

end
