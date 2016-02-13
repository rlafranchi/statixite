$(document).ajaxStart(function() {
  $("#ajaxLoader").show();
});

$(document).ajaxStop(function() {
  $("#ajaxLoader").hide();
});

$(document).ajaxError(function(event, jqXHR) {
  if ( jqXHR.status == 401 ) {
    window.location.replace('/users/sign_in');
  }
});

