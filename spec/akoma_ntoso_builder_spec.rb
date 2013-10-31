require 'spec_helper'

require 'steno/akoma_ntoso_builder'

describe Steno::AkomaNtosoBuilder do
  describe '#nest_blocklists' do
    it 'should nest simple blocks' do
      doc = xml2doc(subsection(<<XML
            <blockList id="section-10.1.lst0">
              <item id="section-10.1.lst0.a">
                <num>(a)</num>
                <p>foo</p>
              </item>
              <item id="section-10.1.lst0.i">
                <num>(i)</num>
                <p>item-i</p>
              </item>
              <item id="section-10.1.lst0.ii">
                <num>(ii)</num>
                <p>item-ii</p>
              </item>
              <item id="section-10.1.lst0.iii">
                <num>(iii)</num>
                <p>item-iii</p>
              </item>
              <item id="section-10.1.lst0.aa">
                <num>(aa)</num>
                <p>item-aa</p>
              </item>
              <item id="section-10.1.lst0.bb">
                <num>(bb)</num>
                <p>item-bb</p>
              </item>
            </blockList>
XML
      ))

      subject.nest_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList id="section-10.1.lst0">
              <item id="section-10.1.lst0.a">
                <num>(a)</num>
                <blockList id="section-10.1.lst0.a.list0">
                  <listIntroduction>foo</listIntroduction>
                  <item id="section-10.1.lst0.a.list0.i">
                    <num>(i)</num>
                    <p>item-i</p>
                  </item>
                  <item id="section-10.1.lst0.a.list0.ii">
                    <num>(ii)</num>
                    <p>item-ii</p>
                  </item>
                  <item id="section-10.1.lst0.a.list0.iii">
                    <num>(iii)</num>
                    <blockList id="section-10.1.lst0.a.list0.iii.list0">
                      <listIntroduction>item-iii</listIntroduction>
                      <item id="section-10.1.lst0.a.list0.iii.list0.aa">
                        <num>(aa)</num>
                        <p>item-aa</p>
                      </item>
                      <item id="section-10.1.lst0.a.list0.iii.list0.bb">
                        <num>(bb)</num>
                        <p>item-bb</p>
                      </item>
                    </blockList>
                  </item>
                </blockList>
              </item>
            </blockList>
XML
      )
    end

    # -------------------------------------------------------------------------

    it 'should jump back up a level' do
      doc = xml2doc(subsection(<<XML
            <blockList id="section-10.1.lst0">
              <item id="section-10.1.lst0.a">
                <num>(a)</num>
                <p>foo</p>
              </item>
              <item id="section-10.1.lst0.i">
                <num>(i)</num>
                <p>item-i</p>
              </item>
              <item id="section-10.1.lst0.ii">
                <num>(ii)</num>
                <p>item-ii</p>
              </item>
              <item id="section-10.1.lst0.c">
                <num>(c)</num>
                <p>item-c</p>
              </item>
            </blockList>
XML
      ))

      subject.nest_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList id="section-10.1.lst0">
              <item id="section-10.1.lst0.a">
                <num>(a)</num>
                <blockList id="section-10.1.lst0.a.list0">
                  <listIntroduction>foo</listIntroduction>
                  <item id="section-10.1.lst0.a.list0.i">
                    <num>(i)</num>
                    <p>item-i</p>
                  </item>
                  <item id="section-10.1.lst0.a.list0.ii">
                    <num>(ii)</num>
                    <p>item-ii</p>
                  </item>
                </blockList>
              </item>
              <item id="section-10.1.lst0.c">
                <num>(c)</num>
                <p>item-c</p>
              </item>
            </blockList>
XML
      )
    end

    # -------------------------------------------------------------------------

    it 'should handle (i) correctly' do
      doc = xml2doc(subsection(<<XML
            <blockList id="section-10.1.lst0">
              <item id="section-10.1.lst0.h">
                <num>(h)</num>
                <p>foo</p>
              </item>
              <item id="section-10.1.lst0.i">
                <num>(i)</num>
                <p>item-i</p>
              </item>
              <item id="section-10.1.lst0.j">
                <num>(j)</num>
                <p>item-ii</p>
              </item>
            </blockList>
XML
      ))

      subject.nest_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList id="section-10.1.lst0">
              <item id="section-10.1.lst0.h">
                <num>(h)</num>
                <p>foo</p>
              </item>
              <item id="section-10.1.lst0.i">
                <num>(i)</num>
                <p>item-i</p>
              </item>
              <item id="section-10.1.lst0.j">
                <num>(j)</num>
                <p>item-ii</p>
              </item>
            </blockList>
XML
      )
    end

    # -------------------------------------------------------------------------

    it 'should handle deeply nested lists' do
      doc = xml2doc(subsection(<<XML
        <blockList id="list0">
          <item id="list0.a">
            <num>(a)</num>
            <p>foo</p>
          </item>
          <item id="list0.b">
            <num>(b)</num>
            <p>item-b</p>
          </item>
          <item id="list0.i">
            <num>(i)</num>
            <p>item-b-i</p>
          </item>
          <item id="list0.aa">
            <num>(aa)</num>
            <p>item-i-aa</p>
          </item>
          <item id="list0.bb">
            <num>(bb)</num>
            <p>item-i-bb</p>
          </item>
          <item id="list0.ii">
            <num>(ii)</num>
            <p>item-b-ii</p>
          </item>
          <item id="list0.c">
            <num>(c)</num>
            <p>item-c</p>
          </item>
          <item id="list0.i">
            <num>(i)</num>
            <p>item-c-i</p>
          </item>
          <item id="list0.ii">
            <num>(ii)</num>
            <p>item-c-ii</p>
          </item>
          <item id="list0.iii">
            <num>(iii)</num>
            <p>item-c-iii</p>
          </item>
        </blockList>
XML
    ))

      subject.nest_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList id="list0">
              <item id="list0.a">
                <num>(a)</num>
                <p>foo</p>
              </item>
              <item id="list0.b">
                <num>(b)</num>
                <blockList id="list0.b.list0">
                  <listIntroduction>item-b</listIntroduction>
                  <item id="list0.b.list0.i">
                    <num>(i)</num>
                    <blockList id="list0.b.list0.i.list0">
                      <listIntroduction>item-b-i</listIntroduction>
                      <item id="list0.b.list0.i.list0.aa">
                        <num>(aa)</num>
                        <p>item-i-aa</p>
                      </item>
                      <item id="list0.b.list0.i.list0.bb">
                        <num>(bb)</num>
                        <p>item-i-bb</p>
                      </item>
                    </blockList>
                  </item>
                  <item id="list0.b.list0.ii">
                    <num>(ii)</num>
                    <p>item-b-ii</p>
                  </item>
                </blockList>
              </item>
              <item id="list0.c">
                <num>(c)</num>
                <blockList id="list0.c.list1">
                  <listIntroduction>item-c</listIntroduction>
                  <item id="list0.c.list1.i">
                    <num>(i)</num>
                    <p>item-c-i</p>
                  </item>
                  <item id="list0.c.list1.ii">
                    <num>(ii)</num>
                    <p>item-c-ii</p>
                  </item>
                  <item id="list0.c.list1.iii">
                    <num>(iii)</num>
                    <p>item-c-iii</p>
                  </item>
                </blockList>
              </item>
            </blockList>
XML
        )
    end

    # -------------------------------------------------------------------------

    it 'should jump back up a level when finding (i) near (h)' do
      doc = xml2doc(subsection(<<XML
            <blockList id="section-10.1.lst0">
              <item id="section-10.1.lst0.h">
                <num>(h)</num>
                <p>foo</p>
              </item>
              <item id="section-10.1.lst0.i">
                <num>(i)</num>
                <p>item-i</p>
              </item>
              <item id="section-10.1.lst0.ii">
                <num>(ii)</num>
                <p>item-ii</p>
              </item>
              <item id="section-10.1.lst0.i">
                <num>(i)</num>
                <p>item-i</p>
              </item>
            </blockList>
XML
      ))

      subject.nest_blocklists(doc)
      doc.to_s.should == subsection(<<XML
            <blockList id="section-10.1.lst0">
              <item id="section-10.1.lst0.h">
                <num>(h)</num>
                <blockList id="section-10.1.lst0.h.list0">
                  <listIntroduction>foo</listIntroduction>
                  <item id="section-10.1.lst0.h.list0.i">
                    <num>(i)</num>
                    <p>item-i</p>
                  </item>
                  <item id="section-10.1.lst0.h.list0.ii">
                    <num>(ii)</num>
                    <p>item-ii</p>
                  </item>
                </blockList>
              </item>
              <item id="section-10.1.lst0.i">
                <num>(i)</num>
                <p>item-i</p>
              </item>
            </blockList>
XML
      )
    end
  end
end
