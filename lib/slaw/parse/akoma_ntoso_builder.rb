require 'builder'
require 'nokogiri'

require 'logging'

require 'slaw/namespaces'
require 'slaw/parse/blocklists'
require 'slaw/nokogiri_helpers'

module Slaw
  module Parse
    class AkomaNtosoBuilder
      include Slaw::Namespaces
      include Logging

      # Generate an XML document from the given syntax tree.
      def xml_from_syntax_tree(tree)
        s = ""
        builder = Builder::XmlMarkup.new(indent: 2, target: s)

        builder.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
        builder.akomaNtoso("xmlns:xsi"=> "http://www.w3.org/2001/XMLSchema-instance", 
                           "xsi:schemaLocation" => "http://www.akomantoso.org/2.0 akomantoso20.xsd",
                           "xmlns" => AN) { |b|
          tree.to_xml(b)
        }

        s
      end

      def parse_xml(xml)
        Nokogiri::XML(xml, &:noblanks)
      end

      def to_xml(doc)
        doc.to_xml(indent: 2)
      end

      # Run various postprocesses on the XML, and return
      # the updated XML.
      def postprocess(doc)
        normalise_headings(doc)
        find_short_title(doc)
        sanitise(doc)
      end

      # Do sanitisations, such as finding and linking definitions
      def sanitise(doc)
        link_definitions(doc)
        nest_blocklists(doc)
      end

      # recalculate ids for <term> elements
      def renumber_terms(doc)
        logger.info("Renumbering terms")

        doc.xpath('//a:term', a: AN).each_with_index do |term, i|
          term['id'] = "trm#{i}"
        end
      end

      # Change CAPCASE headings into Sentence case.
      def normalise_headings(doc)
        logger.info("Normalising headings")

        nodes = doc.xpath('//a:body//a:heading/text()', a: AN) +
                doc.xpath('//a:component/a:doc[@name="schedules"]//a:heading/text()', a: AN)

        nodes.each do |heading|
          heading.content = heading.content.downcase.gsub(/^\w/) { $&.upcase }
        end
      end

      # Find the short title and add it as an FRBRalias element in the meta section
      def find_short_title(doc)
        logger.info("Finding short title")

        # Short title and commencement 
        # 8. This Act shall be called the Legal Aid Amendment Act, 1996, and shall come 
        # into operation on a date fixed by the President by proclamation in the Gazette. 

        doc.xpath('//a:body//a:heading[contains(text(), "hort title")]', a: AN).each do |heading|
          section = heading.parent.at_xpath('a:subsection', a: AN)
          if section and section.text =~ /this act (is|shall be called) the (([a-zA-Z\(\)]\s*)+, \d\d\d\d)/i
            short_title = $2

            logger.info("+ Found title: #{short_title}")

            node = doc.at_xpath('//a:meta//a:FRBRalias', a: AN)
            node['value'] = short_title
            break
          end
        end
      end

      # Find definitions of terms and introduce them into the
      # meta section of the document.
      def link_definitions(doc)
        logger.info("Finding and linking definitions")

        terms = find_definitions(doc)
        add_terms_to_references(doc, terms)
        find_term_references(doc, terms)
        renumber_terms(doc)
      end

      def find_definitions(doc)
        guess_at_definitions(doc)

        terms = {}
        doc.xpath('//a:def', a: AN).each do |defn|
          # <p>"<def refersTo="#term-affected_land">affected land</def>" means land in respect of which an application has been lodged in terms of section 17(1);</p>
          id = defn['refersTo'].sub(/^#/, '')
          term = defn.content
          terms[id] = term

          logger.info("+ Found definition for: #{term}")
        end

        terms
      end

      def guess_at_definitions(doc)
        doc.xpath('//a:section', a: AN).select do |section|
          # sections with headings like Definitions
          heading = section.at_xpath('a:heading', a: AN)
          heading && heading.content =~ /definitions|interpretation/i
        end.each do |section|
          # find items like "foo" means blah...
          
          section.xpath('.//a:p|.//a:listIntroduction', a: AN).each do |container|
            # only if we don't already have a definition here
            next if container.at_xpath('a:def', a: AN)

            # get first text node
            text = container.children.first
            next if (not text or not text.text?)

            match = /^\s*["“”](.+?)["“”]/.match(text.text)
            if match
              term = match.captures[0]
              term_id = 'term-' + term.gsub(/[^a-zA-Z0-9_-]/, '_')

              # <p>"<def refersTo="#term-affected_land">affected land</def>" means land in respect of which an application has been lodged in terms of section 17(1);</p>
              defn = doc.create_element('def', term, refersTo: "##{term_id}")
              rest = match.post_match

              text.before(defn)
              defn.before(doc.create_text_node('"'))
              text.content = '"' + rest

              # adjust the container's id
              parent = find_up(container, ['blockList', 'point']) || find_up(container, ['subsection', 'section'])
              parent['id'] = "def-#{term_id}"
            end
          end
        end
      end
      
      def add_terms_to_references(doc, terms)
        refs = doc.at_xpath('//a:meta/a:references', a: AN)
        unless refs
          refs = doc.create_element('references', source: "#this")
          doc.at_xpath('//a:meta/a:identification', a: AN).after(refs)
        end

        # nuke all existing term reference elements
        refs.xpath('a:TLCTerm', a: AN).each { |el| el.remove }

        for id, term in terms
          # <TLCTerm id="term-applicant" href="/ontology/term/this.eng.applicant" showAs="Applicant"/>
          refs << doc.create_element('TLCTerm',
                                     id: id,
                                     href: "/ontology/term/this.eng.#{id.gsub(/^term-/, '')}",
                                     showAs: term)
        end
      end

      # Find and decorate references to terms in the document.
      # The +terms+ param is a hash from term_id to actual term.
      def find_term_references(doc, terms)
        logger.info("+ Finding references to terms")

        i = 0

        # sort terms by the length of the defined term, desc,
        # so that we don't find short terms inside longer
        # terms
        terms = terms.to_a.sort_by { |pair| -pair[1].size }

        # look for each term
        for term_id, term in terms
          doc.xpath('//a:body//text()', a: AN).each do |text|
            # replace all occurrences in this text node

            # unless we're already inside a def or term element
            next if (["def", "term"].include?(text.parent.name))

            # don't link to a term inside its own definition
            owner = find_up(text, 'subsection')
            next if owner and owner.at_xpath(".//a:def[@refersTo='##{term_id}']", a: AN)

            while posn = (text.content =~ /\b#{Regexp::escape(term)}\b/)
              # <p>A delegation under subsection (1) shall not prevent the <term refersTo="#term-Minister" id="trm357">Minister</term> from exercising the power himself or herself.</p>
              node = doc.create_element('term', term, refersTo: "##{term_id}", id: "trm#{i}")

              pre = (posn > 0) ? text.content[0..posn-1] : nil
              post = text.content[posn+term.length..-1]

              text.before(node)
              node.before(doc.create_text_node(pre)) if pre
              text.content = post

              i += 1
            end
          end
        end
      end

      def nest_blocklists(doc)
        logger.info("Nesting blocklists")

        Slaw::Parse::Blocklists.nest_blocklists(doc)
      end

      protected

      # Look up the parent chain for an element that matches the given
      # node name
      def find_up(node, names)
        names = Array(names)

        for parent in node.ancestors
          return parent if names.include?(parent.name)
        end

        nil
      end
    end
  end
end
