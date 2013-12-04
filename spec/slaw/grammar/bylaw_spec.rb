require 'slaw/parse/parser'

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
      node.blocklist.elements.first.num.should == "a"
    end

    it 'should handle a blocklist' do
      node = parse :subsection, <<EOS
        (2) title
        (a) one
        (b) two
        (c) three
        (i) four
EOS
      node.statement.num.should == "2"
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
      node.blocklist.elements.first.num.should == "a"
      node.blocklist.elements.first.content.text_value.should == "one"
    end
  end

  describe 'numbered_statement' do
    it 'should handle basic numbered statements' do
      should_parse :numbered_statement, '(1) foo bar'
      should_parse :numbered_statement, '(1a) foo bar'
    end
  end

  describe 'bylaw' do
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
      section.section_title.content.text_value.should == "Section"
      section.section_title.section_title_prefix.number_letter.text_value.should == "1"
    end
  end
end
