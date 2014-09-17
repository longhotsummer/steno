module Steno
  module Helpers
    include Slaw::Namespace

    def toc_items(doc)
      doc.at_xpath('/a:akomaNtoso/a:act/a:body', a: NS).elements
    end
  end
end
