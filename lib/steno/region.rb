module Steno
  class Region
    attr_accessor :name
    attr_accessor :code
    attr_accessor :council
    attr_accessor :province
    attr_accessor :gazette

    def initialize(hash={})
      (hash || {}).each_pair { |k, v| self.send("#{k}=", v) }

      self.code = name.downcase.gsub(' ', '-') if !code
      self.council = "#{name} City Council" if !council
      self.gazette = "Province of #{province}: Provincial Gazette"
    end

    REGIONS = [
      Region.new(name: 'Buffalo City',  province: "Eastern Cape", council: 'Buffalo City Municipality Council'),
      Region.new(name: 'Cape Town',     province: "Western Cape"),
      Region.new(name: 'Ekurhuleni',    province: "Gauteng", council: 'Ekurhuleni Municipality Council'),
      Region.new(name: 'Johannesburg',  province: "Gauteng"),
      Region.new(name: 'Mangaung',      province: "Free State", council: 'Mangaung Municipality Council'),
      Region.new(name: 'Nelson Mandela Bay', province: "Eastern Cape", council: 'Nelson Mandela Bay Municipality Council'),
      Region.new(name: 'Tshwane',       province: "Gauteng"),
      Region.new(name: 'eThekwini',     province: "KwaZulu-Natal", council: 'eThekwini Municipality Council'),
    ]

    def self.for_code(code)
      REGIONS.find { |r| r.code == code }
    end
  end

end
