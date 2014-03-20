//= require bootstrap
//= require steno

$(function() {
  window.steno = new Steno.App();
  window.steno.init();

  $(window).on('beforeunload', function(e) {
    e.preventDefault();
    return 'You will lose your changes!';
  });
});
