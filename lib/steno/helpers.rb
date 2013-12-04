module Steno
  module Helpers
    include Slaw::Namespaces

    def toc_items(doc)
      doc.at_xpath('/a:akomaNtoso/a:act/a:body', a: AN).elements
    end
  end
end
