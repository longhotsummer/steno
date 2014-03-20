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

  describe 'numbered_statement' do
    it 'should handle basic numbered statements' do
      should_parse :numbered_statement, '(1) foo bar'
      should_parse :numbered_statement, '(1a) foo bar'
    end
  end

  describe 'bylaw' do
    context 'preamble' do
      it 'should consider any text at the start to be preamble' do
        node = parse :bylaw, <<EOS
foo
bar
baz
1. Section
(1) hello
EOS

        node.elements.first.text_value.should == "foo\nbar\nbaz\n"
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
