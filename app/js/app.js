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

    Steno.sourceTextEd.setValue(data.source_text);
    $('#doc_xml').val(data.xml);
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
