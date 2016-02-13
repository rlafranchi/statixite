var deployment = new Vue({
  el: "#deploymentModal",
  data: {},
  methods: {
    addDeployment: function(e, submit) {
      e.preventDefault();
      if ( submit ) {
        $('form').submit();
      }
    }
  }
})

