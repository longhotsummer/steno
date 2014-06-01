require 'spec_helper'
require 'steno/document_parser'

describe Steno::DocumentParser do
  it 'should handle a basic parse' do
    doc = subject.parse("PREAMBLE\nfoo\n1. Stuff\n(1) hello")
    subject.parse_errors.should == []

    doc.xml.should == <<XML
<?xml version="1.0" encoding="UTF-8"?>
<akomaNtoso xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.akomantoso.org/2.0" xsi:schemaLocation="http://www.akomantoso.org/2.0 akomantoso20.xsd">
  <act contains="originalVersion">
    <meta>
      <identification source="#openbylaws">
        <FRBRWork>
          <FRBRthis value="/za/by-law/locale/1980/name/main"/>
          <FRBRuri value="/za/by-law/locale/1980/name"/>
          <FRBRalias value="By-Law Short Title"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council" as="#author"/>
          <FRBRcountry value="za"/>
        </FRBRWork>
        <FRBRExpression>
          <FRBRthis value="/za/by-law/locale/1980/name/main/eng@"/>
          <FRBRuri value="/za/by-law/locale/1980/name/eng@"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council" as="#author"/>
          <FRBRlanguage language="eng"/>
        </FRBRExpression>
        <FRBRManifestation>
          <FRBRthis value="/za/by-law/locale/1980/name/main/eng@"/>
          <FRBRuri value="/za/by-law/locale/1980/name/eng@"/>
          <FRBRdate date="#{Time.now.strftime('%Y-%m-%d')}" name="Generation"/>
          <FRBRauthor href="#openbylaws" as="#author"/>
        </FRBRManifestation>
      </identification>
      <publication date="1980-01-01" name="Province of Western Cape: Provincial Gazette" number="XXXX" showAs="Province of Western Cape: Provincial Gazette"/>
      <references source="#this">
        <TLCOrganization id="openbylaws" href="http://openbylaws.org.za" showAs="openbylaws.org.za"/>
        <TLCOrganization id="council" href="/ontology/organization/za/council.cape-town" showAs="Cape Town City Council"/>
        <TLCRole id="author" href="/ontology/role/author" showAs="Author"/>
      </references>
    </meta>
    <preamble>
      <p>foo</p>
    </preamble>
    <body>
      <section id="section-1">
        <num>1.</num>
        <heading>Stuff</heading>
        <subsection id="section-1.1">
          <num>(1)</num>
          <content>
            <p>hello</p>
          </content>
        </subsection>
      </section>
    </body>
  </act>
</akomaNtoso>
XML

    doc.validate!
    doc.validate_errors.should == []
    doc.validates?.should be_true
  end

  it 'should handle a parse with schedules' do
    s = <<EOS
1. Foo
Stuff and some things.
Schedule 1
The Title of the Schedule
Some lines of text.
EOS
    doc = subject.parse(s)
    subject.parse_errors.should == []

    doc.xml.should == <<XML
<?xml version="1.0" encoding="UTF-8"?>
<akomaNtoso xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.akomantoso.org/2.0" xsi:schemaLocation="http://www.akomantoso.org/2.0 akomantoso20.xsd">
  <act contains="originalVersion">
    <meta>
      <identification source="#openbylaws">
        <FRBRWork>
          <FRBRthis value="/za/by-law/locale/1980/name/main"/>
          <FRBRuri value="/za/by-law/locale/1980/name"/>
          <FRBRalias value="By-Law Short Title"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council" as="#author"/>
          <FRBRcountry value="za"/>
        </FRBRWork>
        <FRBRExpression>
          <FRBRthis value="/za/by-law/locale/1980/name/main/eng@"/>
          <FRBRuri value="/za/by-law/locale/1980/name/eng@"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council" as="#author"/>
          <FRBRlanguage language="eng"/>
        </FRBRExpression>
        <FRBRManifestation>
          <FRBRthis value="/za/by-law/locale/1980/name/main/eng@"/>
          <FRBRuri value="/za/by-law/locale/1980/name/eng@"/>
          <FRBRdate date="#{Time.now.strftime('%Y-%m-%d')}" name="Generation"/>
          <FRBRauthor href="#openbylaws" as="#author"/>
        </FRBRManifestation>
      </identification>
      <publication date="1980-01-01" name="Province of Western Cape: Provincial Gazette" number="XXXX" showAs="Province of Western Cape: Provincial Gazette"/>
      <references source="#this">
        <TLCOrganization id="openbylaws" href="http://openbylaws.org.za" showAs="openbylaws.org.za"/>
        <TLCOrganization id="council" href="/ontology/organization/za/council.cape-town" showAs="Cape Town City Council"/>
        <TLCRole id="author" href="/ontology/role/author" showAs="Author"/>
      </references>
    </meta>
    <body>
      <section id="section-1">
        <num>1.</num>
        <heading>Foo</heading>
        <subsection id="section-1.subsection-0">
          <content>
            <p>Stuff and some things.</p>
          </content>
        </subsection>
      </section>
    </body>
  </act>
  <components>
    <component id="component-0">
      <doc name="schedules">
        <meta>
          <identification source="#openbylaws">
            <FRBRWork>
              <FRBRthis value="/za/by-law/locale/1980/name/main/schedules"/>
              <FRBRuri value="/za/by-law/locale/1980/name/schedules"/>
              <FRBRdate date="1980-01-01" name="Generation"/>
              <FRBRauthor href="#council" as="#author"/>
              <FRBRcountry value="za"/>
            </FRBRWork>
            <FRBRExpression>
              <FRBRthis value="/za/by-law/locale/1980/name/main//schedules/eng@"/>
              <FRBRuri value="/za/by-law/locale/1980/name/schedules/eng@"/>
              <FRBRdate date="1980-01-01" name="Generation"/>
              <FRBRauthor href="#council" as="#author"/>
              <FRBRlanguage language="eng"/>
            </FRBRExpression>
            <FRBRManifestation>
              <FRBRthis value="/za/by-law/locale/1980/name/main/schedules/eng@"/>
              <FRBRuri value="/za/by-law/locale/1980/name/schedules/eng@"/>
              <FRBRdate date="#{Time.now.strftime('%Y-%m-%d')}" name="Generation"/>
              <FRBRauthor href="#openbylaws" as="#author"/>
            </FRBRManifestation>
          </identification>
        </meta>
        <mainBody>
          <chapter id="schedule-1">
            <num>1</num>
            <heading>The title of the schedule</heading>
            <section id="schedule-1.section-0">
              <content>
                <p>Some lines of text.</p>
              </content>
            </section>
          </chapter>
        </mainBody>
      </doc>
    </component>
  </components>
</akomaNtoso>
XML

    doc.validate!
    doc.validate_errors.should == []
    doc.validates?.should be_true
  end

  it 'should handle a parse with ONLY schedules' do
    s = <<EOS
Schedule
My Cool Schedule
Welcome to this schedule.
EOS
    doc = subject.parse(s)
    subject.parse_errors.should == []

    doc.xml.should == <<XML
<?xml version="1.0" encoding="UTF-8"?>
<akomaNtoso xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.akomantoso.org/2.0" xsi:schemaLocation="http://www.akomantoso.org/2.0 akomantoso20.xsd">
  <act contains="originalVersion">
    <meta>
      <identification source="#openbylaws">
        <FRBRWork>
          <FRBRthis value="/za/by-law/locale/1980/name/main"/>
          <FRBRuri value="/za/by-law/locale/1980/name"/>
          <FRBRalias value="By-Law Short Title"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council" as="#author"/>
          <FRBRcountry value="za"/>
        </FRBRWork>
        <FRBRExpression>
          <FRBRthis value="/za/by-law/locale/1980/name/main/eng@"/>
          <FRBRuri value="/za/by-law/locale/1980/name/eng@"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council" as="#author"/>
          <FRBRlanguage language="eng"/>
        </FRBRExpression>
        <FRBRManifestation>
          <FRBRthis value="/za/by-law/locale/1980/name/main/eng@"/>
          <FRBRuri value="/za/by-law/locale/1980/name/eng@"/>
          <FRBRdate date="#{Time.now.strftime('%Y-%m-%d')}" name="Generation"/>
          <FRBRauthor href="#openbylaws" as="#author"/>
        </FRBRManifestation>
      </identification>
      <publication date="1980-01-01" name="Province of Western Cape: Provincial Gazette" number="XXXX" showAs="Province of Western Cape: Provincial Gazette"/>
      <references source="#this">
        <TLCOrganization id="openbylaws" href="http://openbylaws.org.za" showAs="openbylaws.org.za"/>
        <TLCOrganization id="council" href="/ontology/organization/za/council.cape-town" showAs="Cape Town City Council"/>
        <TLCRole id="author" href="/ontology/role/author" showAs="Author"/>
      </references>
    </meta>
    <body>
    </body>
  </act>
  <components>
    <component id="component-0">
      <doc name="schedules">
        <meta>
          <identification source="#openbylaws">
            <FRBRWork>
              <FRBRthis value="/za/by-law/locale/1980/name/main/schedules"/>
              <FRBRuri value="/za/by-law/locale/1980/name/schedules"/>
              <FRBRdate date="1980-01-01" name="Generation"/>
              <FRBRauthor href="#council" as="#author"/>
              <FRBRcountry value="za"/>
            </FRBRWork>
            <FRBRExpression>
              <FRBRthis value="/za/by-law/locale/1980/name/main//schedules/eng@"/>
              <FRBRuri value="/za/by-law/locale/1980/name/schedules/eng@"/>
              <FRBRdate date="1980-01-01" name="Generation"/>
              <FRBRauthor href="#council" as="#author"/>
              <FRBRlanguage language="eng"/>
            </FRBRExpression>
            <FRBRManifestation>
              <FRBRthis value="/za/by-law/locale/1980/name/main/schedules/eng@"/>
              <FRBRuri value="/za/by-law/locale/1980/name/schedules/eng@"/>
              <FRBRdate date="#{Time.now.strftime('%Y-%m-%d')}" name="Generation"/>
              <FRBRauthor href="#openbylaws" as="#author"/>
            </FRBRManifestation>
          </identification>
        </meta>
        <mainBody>
          <chapter id="schedules">
            <heading>My cool schedule</heading>
            <section id="schedules.section-0">
              <content>
                <p>Welcome to this schedule.</p>
              </content>
            </section>
          </chapter>
        </mainBody>
      </doc>
    </component>
  </components>
</akomaNtoso>
XML

    # this document technically doesn't validate because the body has no content,
    # but let's not worry about that
  end

  it 'should ignore schedules part way through' do
    s = <<EOS
1. Things
Some stuff that may have to do with schedules.
Schedule 1
something
Schedule 2
something
A statement or similar.
2. Another section
Some stuff in it.
Schedule "1"
A Title
1. Blah
Schedule 2
Another Title
Boom
EOS
    doc = subject.parse(s)
    subject.parse_errors.should == []

    doc.xml.should == <<XML
<?xml version="1.0" encoding="UTF-8"?>
<akomaNtoso xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.akomantoso.org/2.0" xsi:schemaLocation="http://www.akomantoso.org/2.0 akomantoso20.xsd">
  <act contains="originalVersion">
    <meta>
      <identification source="#openbylaws">
        <FRBRWork>
          <FRBRthis value="/za/by-law/locale/1980/name/main"/>
          <FRBRuri value="/za/by-law/locale/1980/name"/>
          <FRBRalias value="By-Law Short Title"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council" as="#author"/>
          <FRBRcountry value="za"/>
        </FRBRWork>
        <FRBRExpression>
          <FRBRthis value="/za/by-law/locale/1980/name/main/eng@"/>
          <FRBRuri value="/za/by-law/locale/1980/name/eng@"/>
          <FRBRdate date="1980-01-01" name="Generation"/>
          <FRBRauthor href="#council" as="#author"/>
          <FRBRlanguage language="eng"/>
        </FRBRExpression>
        <FRBRManifestation>
          <FRBRthis value="/za/by-law/locale/1980/name/main/eng@"/>
          <FRBRuri value="/za/by-law/locale/1980/name/eng@"/>
          <FRBRdate date="#{Time.now.strftime('%Y-%m-%d')}" name="Generation"/>
          <FRBRauthor href="#openbylaws" as="#author"/>
        </FRBRManifestation>
      </identification>
      <publication date="1980-01-01" name="Province of Western Cape: Provincial Gazette" number="XXXX" showAs="Province of Western Cape: Provincial Gazette"/>
      <references source="#this">
        <TLCOrganization id="openbylaws" href="http://openbylaws.org.za" showAs="openbylaws.org.za"/>
        <TLCOrganization id="council" href="/ontology/organization/za/council.cape-town" showAs="Cape Town City Council"/>
        <TLCRole id="author" href="/ontology/role/author" showAs="Author"/>
      </references>
    </meta>
    <body>
      <section id="section-1">
        <num>1.</num>
        <heading>Things</heading>
        <subsection id="section-1.subsection-0">
          <content>
            <p>Some stuff that may have to do with schedules.</p>
          </content>
        </subsection>
        <subsection id="section-1.subsection-1">
          <content>
            <p>Schedule 1 something</p>
          </content>
        </subsection>
        <subsection id="section-1.subsection-2">
          <content>
            <p>Schedule 2 something</p>
          </content>
        </subsection>
        <subsection id="section-1.subsection-3">
          <content>
            <p>A statement or similar.</p>
          </content>
        </subsection>
      </section>
      <section id="section-2">
        <num>2.</num>
        <heading>Another section</heading>
        <subsection id="section-2.subsection-0">
          <content>
            <p>Some stuff in it.</p>
          </content>
        </subsection>
      </section>
    </body>
  </act>
  <components>
    <component id="component-0">
      <doc name="schedules">
        <meta>
          <identification source="#openbylaws">
            <FRBRWork>
              <FRBRthis value="/za/by-law/locale/1980/name/main/schedules"/>
              <FRBRuri value="/za/by-law/locale/1980/name/schedules"/>
              <FRBRdate date="1980-01-01" name="Generation"/>
              <FRBRauthor href="#council" as="#author"/>
              <FRBRcountry value="za"/>
            </FRBRWork>
            <FRBRExpression>
              <FRBRthis value="/za/by-law/locale/1980/name/main//schedules/eng@"/>
              <FRBRuri value="/za/by-law/locale/1980/name/schedules/eng@"/>
              <FRBRdate date="1980-01-01" name="Generation"/>
              <FRBRauthor href="#council" as="#author"/>
              <FRBRlanguage language="eng"/>
            </FRBRExpression>
            <FRBRManifestation>
              <FRBRthis value="/za/by-law/locale/1980/name/main/schedules/eng@"/>
              <FRBRuri value="/za/by-law/locale/1980/name/schedules/eng@"/>
              <FRBRdate date="#{Time.now.strftime('%Y-%m-%d')}" name="Generation"/>
              <FRBRauthor href="#openbylaws" as="#author"/>
            </FRBRManifestation>
          </identification>
        </meta>
        <mainBody>
          <chapter id="schedule-1">
            <num>1</num>
            <heading>A title</heading>
            <section id="schedule-1.section-0">
              <content>
                <p>1. Blah</p>
              </content>
            </section>
          </chapter>
          <chapter id="schedule-2">
            <num>2</num>
            <heading>Another title</heading>
            <section id="schedule-2.section-0">
              <content>
                <p>Boom</p>
              </content>
            </section>
          </chapter>
        </mainBody>
      </doc>
    </component>
  </components>
</akomaNtoso>
XML

    doc.validate!
    doc.validate_errors.should == []
    doc.validates?.should be_true
  end
end
