var repoBranches = new Vue({
  el: "#buildFrom-custom",
  data: {
    branches: [],
    repo: ""
  },
  methods: {
    findBranches: function(e) {
      e.preventDefault();
      var that = this;
      $.ajax({
        url: "/statixite/sites/repo_branches",
        data: {
          format: 'json',
          repo: that.repo
        },
        success: function(data) {
          that.branches = data.data;
          $.notify(data.message, data.status);
        },
        error: function(response, data) {
          $.notify(response.responseJSON.message,response.responseJSON.status);
        }
      });
    }
  }
});
