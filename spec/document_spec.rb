require 'spec_helper'
require 'steno/document'

describe Steno::Document do
  it 'should handle a basic parse' do
    subject.source_text = "PREAMBLE\nfoo\n1. Stuff\n(1) hello"
    subject.parse!.should be_true

    subject.parse_errors.should == []
    subject.validate_errors.should == []

    subject.validates?.should be_true

    subject.xml.should == <<XML
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
          <FRBRdate date="2013-10-31" name="Generation"/>
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
  end
end
