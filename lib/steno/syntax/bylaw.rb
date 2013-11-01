require 'steno/syntax/act'

module Bylaw
  class Bylaw < Act::Act
    def to_xml(b)
      b.act(contains: "originalVersion") { |b|
        b.meta { |b|
          b.identification(source: "#openbylaws") { |b|
            # TODO: correct values
            b.FRBRWork { |b|
              b.FRBRthis(value: '/za/by-law/locale/1980/name/main')
              b.FRBRuri(value: '/za/by-law/locale/1980/name')
              b.FRBRalias(value: 'By-Law Short Title')
              b.FRBRdate(date: '1980-01-01', name: 'Generation')
              b.FRBRauthor(href: '#council', as: '#author')
              b.FRBRcountry(value: 'za')
            }
            b.FRBRExpression { |b|
              b.FRBRthis(value: '/za/by-law/locale/1980/name/main/eng@')
              b.FRBRuri(value: '/za/by-law/locale/1980/name/eng@')
              b.FRBRdate(date: '1980-01-01', name: 'Generation')
              b.FRBRauthor(href: '#council', as: '#author')
              b.FRBRlanguage(language: 'eng')
            }
            b.FRBRManifestation { |b|
              b.FRBRthis(value: '/za/by-law/locale/1980/name/main/eng@')
              b.FRBRuri(value: '/za/by-law/locale/1980/name/eng@')
              b.FRBRdate(date: Time.now.strftime('%Y-%m-%d'), name: 'Generation')
              b.FRBRauthor(href: '#openbylaws', as: '#author')
            }
          }

          b.publication(date: '1980-01-01',
                        name: 'Province of Western Cape: Provincial Gazette',
                        number: 'XXXX',
                        showAs: 'Province of Western Cape: Provincial Gazette')

          b.references(source: "#this") {
            b.TLCOrganization(id: 'openbylaws', href: 'http://openbylaws.org.za', showAs: "openbylaws.org.za")
            b.TLCOrganization(id: 'council', href: '/ontology/organization/za/council.cape-town', showAs: "Cape Town City Council")
            b.TLCRole(id: 'author', href: '/ontology/role/author', showAs: 'Author')
          }
        }

        if preamble.text_value != ""
          b.preamble { |b|
            preamble.to_xml(b)
          }
        end

        b.body { |b|
          elements[1].elements.each { |e| e.to_xml(b) }
        }
      }
    end

    def preamble
      elements.first
    end
  end
end
