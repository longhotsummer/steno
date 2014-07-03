//= require bootstrap
//= require steno
//= require dropzone-3.10.2.min

Dropzone.autoDiscover = false;

$(function() {
  $('[title]').tooltip();

  window.steno = new Steno.App();
  window.steno.init();

  $(window).on('beforeunload', function(e) {
    e.preventDefault();
    return 'You will lose your changes!';
  });
});
