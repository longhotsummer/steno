var Steno = {
  sourceTextEd: null,

  init: function() {
    $('#form').on('submit', Steno.submitForm);

    var ed;
    Steno.sourceTextEd = ed = ace.edit("doc_source_text");

    ed.setTheme("ace/theme/chrome");
    ed.setShowPrintMargin(false);

    var sess = ed.getSession();
    sess.setMode("ace/mode/text");
    sess.setUseWrapMode(false);
  },

  // refresh the forms based on data received from the server
  update: function(data) {
    console.log(data);

    // update the XML
    $('#doc_xml').val(data.xml);

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
      if (sourceChanged) {
        ed.gotoLine(posn.row+1, posn.column);
      }
    }
    ed.renderer.scrollCursorIntoView();

    // update the HTML
    $('#doc_html').html(data.html);
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

  submitForm: function(e) {
    try {
      $('#parse_btn').addClass('disabled');

      data = $(this).serializeArray();
      data.push({name: 'doc[source_text]', value: Steno.sourceTextEd.getValue()});

      $.ajax('/parse', {
        method: 'POST',
        data: data,
        success: Steno.update,
        complete: function() {
          $('#parse_btn').removeClass('disabled');
        }
      });
    } catch (e) {
      console.log(e);
    }

    return false;
  }
};

$(function() {
  Steno.init();
});
