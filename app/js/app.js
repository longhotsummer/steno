$(function() {
  var refresh = function(data) {
    // refresh the form
    console.log(data);
    $('#doc_source_text').val(data.source_text);
    $('#doc_xml').val(data.xml);
  };

  $('#form').on('submit', function(e) {
    try {
      $('#parse_btn').addClass('disabled');

      $.ajax('/parse', {
        method: 'POST',
        data: $(this).serializeArray(),
        success: function(data, text) {
          refresh(data);
        },
        complete: function() {
          $('#parse_btn').removeClass('disabled');
        }
      });
    } catch (e) {
      console.log(e);
    }

    return false;
  });
});
