//= require bootstrap

var Steno = {
  sourceTextEd: null,
  xmlEd: null,
  syncScrolling: true,

  init: function() {
    $('#parse-btn').on('click', Steno.parseSource);
    $('#source-doc-html').on('scroll', Steno.htmlScroll);
    $('#metadata-step a.btn').on('click', function() {
      $('ul.steps li:eq(1) a').tab('show');
    });

    // source text editor
    var ed;
    Steno.sourceTextEd = ed = ace.edit("source-doc-text");

    ed.setTheme("ace/theme/chrome");
    ed.setShowPrintMargin(false);

    var sess = ed.getSession();
    sess.setMode("ace/mode/text");
    sess.setUseWrapMode(true);

    // xml editor
    Steno.xmlEd = ed = ace.edit("doc-xml");

    ed.setTheme("ace/theme/chrome");
    ed.setShowPrintMargin(false);

    sess = ed.getSession();
    sess.setMode("ace/mode/xml");
    sess.setUseWrapMode(true);
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
    try {
      $('#parse-btn').addClass('disabled');

      var data = $('#source-form').serializeArray();
      data.push({name: 'doc[source_text]', value: Steno.sourceTextEd.getValue()});

      $.ajax('/parse', {
        method: 'POST',
        data: data,
        success: Steno.parsedSource,
        complete: function() {
          $('#parse-btn').removeClass('disabled');
        }
      });
    } catch (e) {
      console.log(e);
    }

    return false;
  },

  // The HTML section scrolled, if we're syncing scrolling,
  // handle it.
  htmlScroll: function() {
    // TODO: scroll all the others, too
    if (Steno.syncScrolling) {
      var $html = $('#source-doc-html');

      var perc = $html.scrollTop() / $html[0].scrollHeight;
      var line = Steno.sourceTextEd.getSession().getLength() * perc;

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
        $('#source-doc-html').html(data.html);
      },
    });
  },
};

$(function() {
  Steno.init();
});
