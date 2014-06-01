require 'slaw/parse/parser'
require 'builder'

describe Slaw::Parse::Parser do
  def parse(rule, s)
    subject.parse_bylaw(s, rule)
  end

  def should_parse(rule, s)
    parser = subject
    tree = parser.parse_bylaw(s, rule)

    if not tree
      raise Exception.new(parser.failure_reason || "Couldn't match to grammar") if tree.nil?
    else
      # count an assertion
      tree.should_not be_nil
    end
  end

  def to_xml(node)
    s = ""
    b = Builder::XmlMarkup.new(target: s)
    node.to_xml(b)
    s
  end

  #-------------------------------------------------------------------------------
  # Chapters
  #
  describe 'chapters' do
    it 'should handle chapter headers' do
      node = parse :chapter, <<EOS
ChaPTEr 2
The Chapter Heading
1. Section
Hello there
EOS
      node.num.should == "2"
      node.heading.title.should == 'The Chapter Heading'
      to_xml(node).should == "<chapter id=\"chapter-2\"><num>2</num><heading>The Chapter Heading</heading><section id=\"section-1\"><num>1.</num><heading>Section</heading><subsection id=\"section-1.subsection-0\"><content><p>Hello there</p></content></subsection></section></chapter>"
    end
  end

  #-------------------------------------------------------------------------------
  # Parts

  describe 'parts' do
    it 'should handle part headers' do
      node = parse :part, <<EOS
pART 2
The Part Heading
1. Section
Hello there
EOS
      node.num.should == "2"
      node.heading.title.should == 'The Part Heading'
      to_xml(node).should == "<part id=\"part-2\"><num>2</num><heading>The Part Heading</heading><section id=\"section-1\"><num>1.</num><heading>Section</heading><subsection id=\"section-1.subsection-0\"><content><p>Hello there</p></content></subsection></section></part>"
    end

    it 'should handle parts and odd section numbers' do
      subject.options = {section_number_after_title: false}
      node = parse :bylaw, <<EOS
PART 1
PREVENTION AND SUPPRESSION OF HEALTH NUISANCES
1.
No owner or occupier of any shop or business premises or vacant land adjoining a shop or business premises shall cause a health nuisance.
EOS

      part = node.elements[1].elements[0].elements[1].elements[0]
      part.heading.num.should == "1"
      part.heading.title.should == "PREVENTION AND SUPPRESSION OF HEALTH NUISANCES"

      section = part.elements[1].elements[0]
      section.section_title.title.should == ""
      section.section_title.section_title_prefix.number_letter.text_value.should == "1"
    end
  end

  #-------------------------------------------------------------------------------
  # Subsections

  describe 'subsection' do
    it 'should handle basic subsections' do
      should_parse :subsection, <<EOS
        (2) foo bar
EOS
    end

    it 'should handle a naked statement' do
      should_parse :subsection, 'naked statement'
    end

    it 'should handle a naked statement and blocklist' do
      node = parse :subsection, <<EOS
        naked statement (c) blah
        (a) foo
        (b) bar
EOS
      node.statement.content.text_value.should == "naked statement (c) blah"
      node.blocklist.elements.first.num.should == "(a)"
    end

    it 'should handle a blocklist' do
      node = parse :subsection, <<EOS
        (2) title
        (a) one
        (b) two
        (c) three
        (i) four
EOS
      node.statement.num.should == "(2)"
      node.statement.content.text_value.should == "title"
    end

    it 'should handle a subsection that dives straight into a list' do
      node = parse(:subsection, <<EOS
        (1) (a) one
        (b) two
        (c) three
        (i) four
EOS
                  )
      node.statement.content.should be_nil
      node.blocklist.elements.first.num.should == "(a)"
      node.blocklist.elements.first.content.text_value.should == "one"
    end

    context 'dotted numbers' do
      it 'should handle dotted number subsection numbers' do
        node = parse :subsection, <<EOS
          9.9. foo
EOS
        node.statement.content.text_value.should == "foo"
        node.statement.num.should == "9.9"
      end

      it 'should handle dotted number sublists' do
        node = parse(:subsection, <<EOS
          9.9 foo
          9.9.1 item1
          9.9.2 item2
          9.9.2.1 item3
EOS
                    )
        node.statement.content.text_value.should == "foo"
        node.blocklist.elements.first.num.should == "9.9.1"
        node.blocklist.elements.first.content.text_value.should == "item1"

        node.blocklist.elements[2].num.should == "9.9.2.1"
        node.blocklist.elements[2].content.text_value.should == "item3"
      end
    end
  end

  #-------------------------------------------------------------------------------
  # Numbered statements

  describe 'numbered_statement' do
    it 'should handle basic numbered statements' do
      should_parse :numbered_statement, '(1) foo bar'
      should_parse :numbered_statement, '(1a) foo bar'
    end
  end

  #-------------------------------------------------------------------------------
  # Preamble

  context 'preamble' do
    it 'should consider any text at the start to be preamble' do
      node = parse :bylaw, <<EOS
foo
bar
(1) stuff
(2) more stuff
baz
1. Section
(1) hello
EOS

      node.elements.first.text_value.should == "foo
bar
(1) stuff
(2) more stuff
baz
"
    end

    it 'should support an optional preamble' do
      node = parse :bylaw, <<EOS
PREAMBLE
foo
1. Section
(1) hello
EOS

      node.elements.first.text_value.should == "PREAMBLE\nfoo\n"
    end

    it 'should support no preamble' do
      node = parse :bylaw, <<EOS
1. Section
bar
EOS

      node.elements.first.text_value.should == ""
    end
  end


  #-------------------------------------------------------------------------------
  # Sections

  context 'sections' do
    it 'should handle section numbers after title' do
      subject.options = {section_number_after_title: true}
      node = parse :bylaw, <<EOS
Section
1. (1) hello
EOS

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[0]
      section.section_title.content.text_value.should == "Section"
      section.section_title.section_title_prefix.number_letter.text_value.should == "1"
    end

    it 'should handle section numbers before title' do
      subject.options = {section_number_after_title: false}
      node = parse :bylaw, <<EOS
1. Section
(1) hello
EOS

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[0]
      section.section_title.title.should == "Section"
      section.section_title.num.should == "1"
    end

    it 'should handle section numbers without a dot' do
      subject.options = {section_number_after_title: false}
      node = parse :bylaw, <<EOS
1 A section
(1) hello
2 Another section
(2) Another line
EOS

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[0]
      section.section_title.title.should == "A section"
      section.section_title.num.should == "1"

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[1]
      section.section_title.title.should == "Another section"
      section.section_title.num.should == "2"
    end

    it 'should handle sections without titles' do
      subject.options = {section_number_after_title: false}
      node = parse :bylaw, <<EOS
1. No owner or occupier of any shop or business premises or vacant land, blah blah
2. Notwithstanding the provision of any other By-law or legislation no person shall—
EOS

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[0]
      section.section_title.title.should == "No owner or occupier of any shop or business premises or vacant land, blah blah"
      section.section_title.num.should == "1"

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[1]
      section.section_title.title.should == ""
      section.section_title.num.should == "2"
      section.subsections.elements[0].statement.content.text_value.should == "Notwithstanding the provision of any other By-law or legislation no person shall—"
    end

    it 'should handle sections without titles and with subsections' do
      subject.options = {section_number_after_title: false}
      node = parse :bylaw, <<EOS
10. (1) Transporters must remove medical waste.
(2) Without limiting generality, stuff.
EOS

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[0]
      section.section_title.title.should == ""
      section.section_title.num.should == "10"
      section.subsections.elements[0].statement.num.should == "(1)"
      section.subsections.elements[0].statement.content.text_value.should == "Transporters must remove medical waste."
    end

    it 'should realise complex section titles are actually section content' do
      subject.options = {section_number_after_title: false}
      node = parse :bylaw, <<EOS
10. The owner of any premises which is let or sublet to more than one tenant, shall maintain at all times in a clean and sanitary condition every part of such premises as may be used in common by more than one tenant.
11. No person shall keep, cause or suffer to be kept any factory or trade premises so as to cause or give rise to smells or effluvia that constitute a health nuisance.
EOS

      section = node.elements[1].elements[0].elements[1].elements[0].elements[1].elements[0]
      section.section_title.title.should == ""
      section.section_title.num.should == "10"
      section.subsections.elements[0].statement.content.text_value.should == "The owner of any premises which is let or sublet to more than one tenant, shall maintain at all times in a clean and sanitary condition every part of such premises as may be used in common by more than one tenant."
    end
  end

  #-------------------------------------------------------------------------------
  # Definitions

  context 'definitions' do
    it 'should handle definitions' do
      node = parse :definitions_section, <<EOS
The follow terms are defined:
"foo" means:
the foo thing;
"bar" means:
the bar thing;
EOS

      defn = node.definitions.elements[0]
      defn.term.should == 'foo'
      defn.content.text_value.should == ' means:'
      defn.definition.elements[0].content.text_value.should == 'the foo thing;'

      defn = node.definitions.elements[1]
      defn.term.should == 'bar'
      defn.content.text_value.should == ' means:'
      defn.definition.elements[0].content.text_value.should == 'the bar thing;'
    end

    it 'should permit reparsing of a section with definitions' do
      sect = parse :section, <<EOS
1. Section title
The follow terms are defined:
"foo" means:
the foo thing;
"bar" means:
the bar thing;
EOS
      definitions = sect.definitions.definitions

      defn = definitions.elements[0]
      defn.term.should == 'foo'
      defn.content.text_value.should == ' means:'
      defn.definition.elements[0].content.text_value.should == 'the foo thing;'

      defn = definitions.elements[1]
      defn.term.should == 'bar'
      defn.content.text_value.should == ' means:'
      defn.definition.elements[0].content.text_value.should == 'the bar thing;'
    end
  end

  #-------------------------------------------------------------------------------
  # schedules

  context 'schedules' do
    it 'should handle a simple schedule' do
      node = parse :schedules, <<EOS
Schedule
Subject to approval in terms of this By-Law, the erection:
1. Foo
2. Bar
EOS

      sched = node.schedules.elements[0]
      sched.schedule_heading.schedule_heading_prefix.text_value.should == "Schedule"
      sched.statements.elements[0].content.text_value.should == "Subject to approval in terms of this By-Law, the erection:"
      sched.statements.elements[1].content.text_value.should == "1. Foo"
      sched.statements.elements[2].content.text_value.should == "2. Bar"
    end

    it 'should handle many schedules' do
      node = parse :schedules, <<EOS
Schedule "1"
A Title
1. Foo
2. Bar
Schedule 2
Another Title
Baz
Boom
EOS

      sched = node.schedules.elements[0]
      sched.schedule_heading.schedule_heading_prefix.text_value.should == "Schedule"
      sched.schedule_heading.schedule_title.content.text_value.should == "A Title"
      sched.schedule_heading.num.text_value.should == "1"
      sched.statements.elements[0].content.text_value.should == "1. Foo"
      sched.statements.elements[1].content.text_value.should == "2. Bar"

      sched = node.schedules.elements[1]
      sched.schedule_heading.schedule_heading_prefix.text_value.should == "Schedule"
      sched.schedule_heading.schedule_title.content.text_value.should == "Another Title"
      sched.schedule_heading.num.text_value.should == "2"
      sched.statements.elements[0].content.text_value.should == "Baz"
      sched.statements.elements[1].content.text_value.should == "Boom"
    end
  end
end
