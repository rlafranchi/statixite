var templateEditor = new Vue({
  el: '#templateTree',
  data: {
    treeData: null,
    currentFile: null
  },
  created: function () {
    var self = this;
    $.ajax({
      url: window.location.href,
      data: {
        format: 'json'
      },
      success: function(response) {
        self.treeData = response;
      }
    });
  },
  methods: {
    saveFileChanges: function () {
      var self = this;
      $.ajax({
        url: window.location.href,
        method: 'POST',
        data: {
          edit: true,
          template: {
            name: self.currentFile.name,
            content: codeEditor.getValue(),
            path: self.currentFile.path
          },
          format: 'json'
        },
        success: function (response) {
          $('.editor-modal').modal('toggle');
          self.treeData = response.template;
          $.notify(response.message, response.status);
          self.currentFile = null;
          codeEditor.setValue('');
        },
        error: function (response) {
          $.notify(response.responseJSON.message, response.responseJSON.status);
        }
      });
    },
    dismissFileChanges: function () {
      $('.editor-modal').modal('toggle');
      this.currentFile = null;
      codeEditor.setValue('');
    }
  },
  components: {
    'file-template': {
      props: ['treedata'],
      template: '#file-template',
      replace: true,
      data: function () {
        return {
          open: false,
          renaming: false
        };
      },
      ready: function () {
        $('[data-toggle="tooltip"]').tooltip();
      },
      computed: {
        isFolder: function () {
          return this.treedata.children && this.treedata.extension == undefined && this.treedata.content == undefined
        },
        editable: function () {
          return this.treedata.editable
        },
        isRoot: function () {
          return this.treedata.root
        },
        isPostsFolder: function () {
          if ( this.treedata.path == '/_posts' ) {
            return true;
          } else {
            return false;
          }
        }
      },
      methods: {
        toggle: function () {
          if (this.isFolder) {
            this.open = !this.open
          }
        },
        addFile: function () {
          var self = this;
          this.treedata.children.push({
            name: 'new_file.md',
            content: '# New File',
            extension: 'md',
            path: this.treedata.path + '/new_file.md',
            new: true
          });
          Vue.nextTick(function() {
            self.$children.last().renaming = true;
          });
        },
        addFolder: function () {
          var self = this;
          this.treedata.children.push({
            name: 'new_folder',
            path: this.treedata.path + '/new_folder',
            children: [],
            new: true
          });
          Vue.nextTick(function() {
            self.$children.last().renaming = true;
          });
        },
        saveName: function (e) {
          e.preventDefault();
          this.renaming = !this.renaming;
          var self = this;
          $.ajax({
            url: window.location.href,
            method: 'POST',
            data: {
              new: self.treedata.new,
              rename: !self.treedata.new,
              template: self.treedata, 
              format: 'json'
            },
            success: function(response) {
              $.notify(response.message, response.status);
              Vue.nextTick(function() {
                $.extend(true, templateEditor.$data.treeData, response.template);
              });
            },
            error: function(response) {
              $.notify(response.responseJSON.message, response.responseJSON.status);
              Vue.nextTick(function() {
                $.extend(true, templateEditor.$data.treeData, response.responseJSON.template);
              });
            }
          });
        },
        renameFile: function() {
          if ( this.treedata.root ) {  
            this.open = !this.open;
          } else {
            this.renaming = !this.renaming;
          }
        },
        editFile: function () {
          if (this.treedata.editable) {
            var mode = '';
            switch (this.treedata.extension) {
              case 'yml':
                mode = 'yaml';
                break;
              case 'js':
                mode = 'javascript';
                break;
              case 'html':
                mode = 'liquid';
                break;
              case 'xml':
                mode = 'liquid';
                break;
              case 'md':
                mode = 'markdown';
                break;
              case 'mkd':
                mode = 'markdown';
                break;
              case 'mkdn':
                mode = 'markdown';
                break;
              case 'mkdown':
                mode = 'markdown';
                break;
              case 'markdown':
                mode = 'markdown';
                break;
              case 'css':
                mode = 'css';
                break;
              case 'scss':
                mode = 'scss';
                break;
              case 'sass':
                mode = 'sass';
                break;
              case 'less':
                mode = 'less';
                break;
              default:
                mode = 'html'
            }
            templateEditor.$data.currentFile = this.treedata;
            codeEditor.getSession().setMode('ace/mode/' + mode);
            codeEditor.setValue(this.treedata.content);
            $('.editor-modal').modal('show');
          }
        },
        openUploadModal: function () {
          templateEditor.$data.currentFile = this.treedata;
          $('.upload-modal').modal('show');
        }
      }
    }
  }
});
