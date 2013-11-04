var Steno = {
  sourceTextEd: null,
  xmlEd: null,
  syncScrolling: true,

  init: function() {
    $('#parse-btn').on('click', Steno.parseSource);
    $('#doc-html').on('scroll', Steno.htmlScroll);

    // source text editor
    var ed;
    Steno.sourceTextEd = ed = ace.edit("doc-source-text");

    ed.setTheme("ace/theme/chrome");
    ed.setShowPrintMargin(false);

    var sess = ed.getSession();
    sess.setMode("ace/mode/text");
    sess.setUseWrapMode(false);

    // xml editor
    Steno.xmlEd = ed = ace.edit("doc-xml");

    ed.setTheme("ace/theme/chrome");
    ed.setShowPrintMargin(false);
    ed.setReadOnly(true);

    sess = ed.getSession();
    sess.setMode("ace/mode/xml");
    sess.setUseWrapMode(false);
  },

  // refresh the forms based on data received from the server
  updateSource: function(data) {
    console.log(data);

    // update the XML
    var ed = Steno.xmlEd;
    ed.setValue(data.xml);
    ed.clearSelection();

    // update the source text
    ed = Steno.sourceTextEd;
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
      if (sourceChanged) {
        ed.gotoLine(posn.row+1, posn.column);
      }
    }
    ed.renderer.scrollCursorIntoView();

    // update the HTML
    $('#doc-html').html(data.html);
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

  parseSource: function(e) {
    try {
      $('#parse-btn').addClass('disabled');

      var data = $('#source-form').serializeArray();
      data.push({name: 'doc[source_text]', value: Steno.sourceTextEd.getValue()});

      $.ajax('/parse', {
        method: 'POST',
        data: data,
        success: Steno.updateSource,
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
      var $html = $('#doc-html');

      var perc = $html.scrollTop() / $html[0].scrollHeight;
      var line = Steno.sourceTextEd.getSession().getLength() * perc;

      Steno.sourceTextEd.scrollToLine(line, false, true);
    }
  },

};

$(function() {
  Steno.init();
});
