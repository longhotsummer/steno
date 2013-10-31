module Act
  # TODO: handle dangling statements at the end of a nested list

  class Act < Treetop::Runtime::SyntaxNode
    def to_xml(b)
      b.act(contains: "originalVersion") { |b|
        b.meta { |b|
          b.identification(source: "#foo") { |b|
            # TODO: correct values
            b.FRBRWork { |b|
              b.FRBRthis(value: '/za/act/1980-01-01/1/main')
              b.FRBRuri(value: '/za/act/1980-01-01/1')
              b.FRBRalias(value: 'Act Short Title')
              b.FRBRdate(date: '1980-01-01', name: 'Generation')
              b.FRBRauthor(href: '#foo', as: '#foo')
              b.FRBRcountry(value: 'za')
            }
            b.FRBRExpression { |b|
              b.FRBRthis(value: 'foo')
              b.FRBRuri(value: 'foo')
              b.FRBRdate(date: '1980-01-01', name: 'Generation')
              b.FRBRauthor(href: '#foo', as: '#foo')
              b.FRBRlanguage(language: 'eng')
            }
            b.FRBRManifestation { |b|
              b.FRBRthis(value: 'foo')
              b.FRBRuri(value: 'foo')
              b.FRBRdate(date: '1980-01-01', name: 'Generation')
              b.FRBRauthor(href: '#foo', as: '#foo')
            }
          }
        }
        b.preamble { |b|
          preamble.to_xml(b)
        }
        b.body { |b|
          elements[1].elements.each { |e| e.to_xml(b) }
        }
      }
    end
  end

  class Frontmatter < Treetop::Runtime::SyntaxNode
  end

  class Preamble < Treetop::Runtime::SyntaxNode
    def to_xml(b)
      # element[0] is the frontmatter
      # element[1] is ACT
      # element[2] is naked_statement collection
      elements[2].elements.each { |e|
        b.p(e.content.text_value)
      }
    end
  end

  class Part < Treetop::Runtime::SyntaxNode
    def num
      if elements.first.is_a? PartHeading
        elements.first.num
      else
        nil
      end
    end

    def to_xml(b)
      # do we have a part heading?
      if elements.first.is_a? PartHeading
        id = "part-#{num}"

        # include a chapter number in the id if our parent has one
        if parent.parent.is_a?(Chapter) and parent.parent.num
          id = "chapter-#{parent.parent.num}.#{id}"
        end

        b.part(id: id) { |b|
          elements.first.to_xml(b)
          elements[1].elements.each { |e| e.to_xml(b) }
        }
      else
        # no parts
        elements[1].elements.each { |e| e.to_xml(b) }
      end
    end
  end

  class PartHeading < Treetop::Runtime::SyntaxNode
    def num
      part_heading_prefix.alphanums.text_value
    end

    def to_xml(b)
      b.num(num)
      b.heading(content.text_value)
    end
  end

  class Chapter < Treetop::Runtime::SyntaxNode
    def num
      if elements.first.is_a? ChapterHeading
        elements.first.num
      else
        nil
      end
    end

    def to_xml(b)
      # do we have a chapter heading?
      if elements.first.is_a? ChapterHeading
        id = "chapter-#{num}"

        # include a part number in the id if our parent has one
        if parent.parent.is_a?(Part) and parent.parent.num
          id = "part-#{parent.parent.num}.#{id}"
        end

        b.chapter(id: id) { |b|
          elements.first.to_xml(b)
          elements[1].elements.each { |e| e.to_xml(b) }
        }
      else
        # no chapters
        elements[1].elements.each { |e| e.to_xml(b) }
      end
    end
  end

  class ChapterHeading < Treetop::Runtime::SyntaxNode
    def num
      chapter_heading_prefix.alphanums.text_value
    end

    def to_xml(b)
      b.num(num)
      b.heading(content.text_value)
    end
  end

  class Section < Treetop::Runtime::SyntaxNode
    def num
      section_title.section_title_prefix.number_letter.text_value
    end

    def title
      section_title.content.text_value
    end

    def subsections
      elements[1].elements
    end

    def to_xml(b)
      id = "section-#{num}"
      b.section(id: id) { |b|
        b.num("#{num}.")
        b.heading(title)

        idprefix = "#{id}."

        if definitions?
          definitions.to_xml(b, idprefix)
        else
          subsections.each_with_index { |e, i| e.to_xml(b, i, idprefix) }
        end
      }
    end

    # is this a definitions section?
    def definitions?
      title =~ /^definition/i
    end

    def definitions
      # Parse the definitions section using the definitions grammar
      @definitions ||= TextActParser.new.parse_definitions(section_content.text_value)
    end
  end

  class Subsection < Treetop::Runtime::SyntaxNode
    def statement
      elements[0]
    end

    def blocklist
      elements[1]
    end

    def to_xml(b, i, idprefix)
      if statement.is_a?(NumberedStatement)
        attribs = {id: idprefix + statement.num}
      else
        attribs = {id: idprefix + "subsection-#{i}"}
      end

      idprefix = attribs[:id] + "."

      b.subsection(attribs) { |b|
        b.num("(#{statement.num})") if statement.is_a?(NumberedStatement)
        
        b.content { |b| 
          if blocklist and blocklist.is_a?(Blocklist)
            if statement.content
              blocklist.to_xml(b, i, idprefix) { |b| b << statement.content.text_value }
            else
              blocklist.to_xml(b, i, idprefix)
            end
          else
            # raw content
            b.p(statement.content.text_value) if statement.content
          end
        }
      }
    end
  end

  class NumberedStatement < Treetop::Runtime::SyntaxNode
    def num
      numbered_statement_prefix.number_letter.text_value
    end

    def content
      if elements[3].text_value == ""
        nil
      else
        elements[3].content
      end
    end
  end

  class NakedStatement < Treetop::Runtime::SyntaxNode
  end

  class Blocklist < Treetop::Runtime::SyntaxNode
    # Render a block list to xml. If a block is given,
    # yield to it a builder to insert a listIntroduction node
    def to_xml(b, i, idprefix, &block)
      id = idprefix + "list#{i}"
      idprefix = id + '.'

      b.blockList(id: id) { |b|
        b.listIntroduction { |b| yield b } if block_given?

        elements.each { |e| e.to_xml(b, idprefix) }
      }
    end
  end

  class BlocklistItem < Treetop::Runtime::SyntaxNode
    def num
      blocklist_item_prefix.letter_ordinal.text_value
    end

    def to_xml(b, idprefix)
      b.item(id: idprefix + num) { |b|
        b.num("(#{num})")
        b.p(content.text_value)
      }
    end
  end

  class DefinitionsSection < Treetop::Runtime::SyntaxNode
    def to_xml(b, idprefix)
      b.list(id: "definitions") { |b| 
        b.intro { |b| b.p(content.text_value) }
        elements[3].elements.each_with_index { |e, i| e.to_xml(b, i, idprefix) }
      }
    end
  end

  class Definition < Treetop::Runtime::SyntaxNode
    def term
      elements[2].text_value
    end

    def term_id
      @term_id ||= term.gsub(/[^a-zA-Z0-9_-]/, '_')
    end

    def to_xml(b, i, idprefix)
      id = "def-term-#{term_id}"
      b.point(id: id) { |b|

        b.subsection(id: id + ".subsection-0") { |b|
          b.content { |b| defn_xml(b) }
        }
        
        elements[6].elements.each_with_index do |child, i|
          section_id = id + ".subsection-#{i+1}"

          b.subsection(id: section_id) { |b|
            b.content { |b|
              child.to_xml(b, i, section_id + ".")
            }
          }
        end
      }
    end

    def defn_xml(b)
      # "<def refersTo="#term-affected_land" id="adef-term-affected_land">affected land</def>" means land in respect of which an application has been lodged in terms of section 17(1);

      # use a supplemental builder to construct a tag without indentation
      s = ""
      b2 = Builder::XmlMarkup.new(target: s)
      b2 << '<p>"'
      b2.def(term, refersTo: "#term-#{term_id}")
      b2 << '"' + content.text_value
      b2 << '</p>'

      b << s
    end
  end

  class DefinitionStatement < Treetop::Runtime::SyntaxNode
    def to_xml(b, i, idprefix)
      b.p(content.text_value)
    end
  end
end
