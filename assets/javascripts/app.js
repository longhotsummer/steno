//= require bootstrap

var Steno = {
  sourceTextEd: null,
  xmlEd: null,
  syncScrolling: true,

  init: function() {
    $('#parse-btn').on('click', Steno.parseSource);
    $('#source-doc-html').on('scroll', Steno.htmlScroll);
    $('#render-btn').on('click', Steno.renderXml);

    $('#metadata-step button.next-step').on('click', function(e) {
      e.preventDefault();
      $('ul.steps li:eq(1) a').tab('show');
    });
    $('#text-step button.next-step').on('click', function(e) {
      e.preventDefault();
      $('ul.steps li:eq(2) a').tab('show');
    });
    $('#xml-step button.next-step').on('click', function(e) {
      e.preventDefault();
      $('ul.steps li:eq(3) a').tab('show');
    });

    // editors
    Steno.sourceTextEd = Steno.createEditor('#text-step .editor', 'ace/mode/text');
    Steno.xmlEd = Steno.createEditor("#xml-step .editor", 'ace/mode/xml');
  },

  /**
   * Create a new editor, using the controls inside
   * +container+.
   *
   * Returns the ACE editor object.
   */
  createEditor: function(container, mode) {
    var ed = ace.edit($('pre', container)[0]);
    ed.setTheme("ace/theme/chrome");
    ed.setShowPrintMargin(false);

    var sess = ed.getSession();
    sess.setMode(mode);
    sess.setUseWrapMode(true);

    // setup search bindings
    $('.editor-controls input[name=search]', container).on('keyup', function(event) {
      // enter key
      if (event.keyCode == 13) {
        ed.findNext();
        return;
      }

      var needle = $(this).val();
      ed.find(
        needle, {
        backwards: false,
        start: {row: 0, column: 0},
        });
    });

    $('.editor-controls .find-next', container).on('click', ed.findNext.bind(ed));
    $('.editor-controls .find-prev', container).on('click', ed.findPrevious.bind(ed));

    return ed;
  },

  /**
   * Update based on a parse of the source text
   */
  parsedSource: function(data) {
    console.log(data);

    // update the source text
    var ed = Steno.sourceTextEd;
    var posn = ed.getCursorPosition();
    var sourceChanged = ed.getValue() != data.source_text;

    if (sourceChanged) {
      ed.setValue(data.source_text);
      ed.clearSelection();
    }

    if (Steno.setParseErrors(data.parse_errors)) {
      // errors
      ed.gotoLine(data.parse_errors[0].line, data.parse_errors[0].column);
      ed.focus();
    } else {
      // no errors
      // kick of a background render
      Steno.renderSourceOutput(data.xml);

      if (sourceChanged) {
        ed.gotoLine(posn.row+1, posn.column);
      }
    }
    ed.renderer.scrollCursorIntoView();

    // update the XML
    ed = Steno.xmlEd;
    ed.setValue(data.xml);
    ed.clearSelection();

  },

  setParseErrors: function(errors) {
    errors = $.map(errors, function(e) { 
      if (e.line && e.column) {
        return {row: e.line-1, column: e.column, text: e.message, type: "error"};
      } else {
        return {};
      }
    });
    Steno.sourceTextEd.getSession().setAnnotations(errors);

    return (errors.length > 0);
  },

  /**
   * Parse the source text of the document.
   */
  parseSource: function(e) {
    e.preventDefault();

    var btn = $('#parse-btn').attr('disabled', 'disabled').addClass('spin');
    var data = $('#source-form').serializeArray();
    data.push({name: 'doc[source_text]', value: Steno.sourceTextEd.getValue()});

    $.ajax('/parse', {
      method: 'POST',
      data: data,
      success: Steno.parsedSource,
      complete: function() {
        btn.removeClass('spin').attr('disabled', null);
      }
    });
  },

  // The HTML section scrolled, if we're syncing scrolling,
  // handle it.
  htmlScroll: function() {
    // TODO: scroll all the others, too
    if (Steno.syncScrolling) {
      var $html = $('#source-doc-html');

      var perc = $html.scrollTop() / $html[0].scrollHeight;
      var line = Math.floor(Steno.sourceTextEd.getSession().getLength() * perc);

      Steno.sourceTextEd.scrollToLine(line, false, true);
    }
  },

  /**
   * Render the source-to-xml output
   */
  renderSourceOutput: function(xml) {
    $.ajax('/render', {
      method: 'POST',
      data: {'doc[xml]': xml},
      success: function(data) {
        // update the HTML
        $('#source-doc-html, #xml-doc-html').html(data.html);
        $('#source-doc-toc, #xml-doc-toc').html(data.toc);
      },
    });
  },

  /**
   * Render the XML editor contents.
   */
  renderXml: function() {
    var xml = Steno.xmlEd.getValue();

    var btn = $('#render-btn').attr('disabled', 'disabled').addClass('spin');

    $.ajax('/render', {
      method: 'POST',
      data: {'doc[xml]': xml},
      success: function(data) {
        // update the HTML
        $('#xml-doc-html').html(data.html);
        $('#xml-doc-toc').html(data.toc);
      },
      complete: function() {
        btn.removeClass('spin').attr('disabled', null);
      }
    });
  },
};

$(function() {
  Steno.init();
});
