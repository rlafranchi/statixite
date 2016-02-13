var jsonContainer = document.getElementById("jsoneditor");
var jsonEditor = new JSONEditor(jsonContainer, {
  change: function() {
    mdEditor.$data.front_matter = jsonEditor.get();
  }
});
function ValidURL(str) {
  var pattern = new RegExp('^(https?:\/\/)?$') // protocol
  if(!pattern.test(str)) {
    return false;
  } else {
    return true;
  }
}
var mdEditor = new Vue({
  el: "#editor",
  data: {
    input: '# hello',
    boldText: '',
    italicText: '',
    listItems: [],
    listItem: '',
    link: {},
    video: {},
    photos: [],
    selectedText: '',
    front_matter: {
      title: ''
    },
    slug: ''
  },
  filters: {
    marked: marked
  },
  created: function () {
    var that = this;
    $(document).ready(function() {
      Dropzone.autoDiscover = false;
      var mediaDropzone;
      mediaDropzone = new Dropzone("#media-dropzone", { addRemoveLinks: false });
      mediaDropzone.on("success", function(file, responseText) {
        $.ajax({
          url: '/statixite/sites/' + responseText.media.site_id + '/media',
          data: {
            format: 'json'
          },
          success: function(response) {
            that.photos = response;
            $.getScript('/statixite/sites/' + response[0].site_id + '/media');
          }
        });
        //that.photos.unshift(responseText.media);
        this.removeFile(file);
        that.input += "\n<!-- Beg Image -->\n";
        that.input += "<img src='" + responseText.media.file.url + "' alt='' style='max-width: 100%; height: auto;'/>\n";
        that.input += "<!-- End Image -->\n";
      });
    });
    $(document).on('click', '.pagination a', {}, function() {
      var link = this;
      $.ajax({
        url: link.href,
        data: {
          format: 'json'
        },
        success: function(response) {
          that.photos = response;
        }
      });
    });
  },
  methods: {
    addBoldText: function() {
      this.input = this.input + " **" + this.boldText + "**";
      this.boldText = '';
      $('#boldText').modal('hide');
    },
    addItalicText: function() {
      this.input = this.input + " *" + this.italicText + "*";
      this.italicText = '';
      $('#italicText').modal('hide');
    },
    addListItem: function() {
      this.listItems.push(this.listItem);
      this.listItem = '';
    },
    addList: function() {
      this.input = this.input + "\n";
      for ( i in this.listItems ) {
        this.input += "* " + this.listItems[i] + "\n"
      }
      this.listItems = [];
      $('#listModal').modal('hide');
    },
    addLink: function() {
      var text = mdEditor.getSelectedText;
      this.input += " [" + this.link.text + "](" + this.link.url +")";
      this.link = {};
      $('#linkModal').modal('hide');
    },
    addVideo: function() {
      var videoEmbed;
      var divStyle = 'height: 0; margin-bottom: 0.88889rem; overflow: hidden; padding-bottom: 67.5%; padding-top: 1.38889rem; position: relative;';
      var iframeStyle = 'height: 100%; position: absolute; top: 0; width: 100%; left: 0;';
      switch(mdEditor.domain) {
        case 'youtu.be':
          var videoArray = this.video.url.split('/');
          var videoId = videoArray[videoArray.length - 1];
          videoEmbed = '<div style="' + divStyle + '"><iframe style="' + iframeStyle + '" src="https://www.youtube.com/embed/' + videoId +'" frameborder="0" allowfullscreen></iframe></div>';
          break;
        case 'www.youtube.com':
          if ( this.video.url.includes('embed') ) {
            videoEmbed = '<div style="' + divStyle + '"><iframe style="' + iframeStyle + '" src="' + this.video.url +'" frameborder="0" allowfullscreen></iframe></div>'
          } else {
            var videoArray = this.video.url.split('v=');
            var videoId = videoArray[videoArray.length - 1];
            videoEmbed = '<div style="' + divStyle + '"><iframe style="' + iframeStyle + '" src="https://www.youtube.com/embed/' + videoId +'" frameborder="0" allowfullscreen></iframe></div>';
          }
          break;
        case 'vimeo.com':
          var videoArray = this.video.url.split('/');
          var videoId = videoArray[videoArray.length - 1];
          videoEmbed = '<div style="' + divStyle + '"><iframe style="' + iframeStyle +'" src="https://player.vimeo.com/video/' + videoId + '" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe></div>';
        default:
          break;
      }
      if ( videoEmbed ) {
        this.input += "\n";
        this.input += "<!-- Video -->\n";
        this.input += videoEmbed;
        this.input += "\n<!-- End Video -->\n";
        this.input += "\n";
      }
      this.video.url = '';
      $('#videoModal').modal('hide');
    },
    cancelModal: function() {
      this.boldText = '';
      this.italicText = '';
      this.listItems = [];
      this.listItem = '';
      this.link = {};
    },
    insertMedia: function(e, media) {
      e.preventDefault();
      var file_url = media.file.url
      this.input += "\n<!-- Beg Image -->\n";
      if ( ValidURL(media.file.url) ) {
        this.input += "<img src='" + media.file.url + "' alt='' style='max-width: 100%; height: auto;'/>\n";
      } else {
        this.input += "<img src='" + file_url.split("clone")[1] + "' alt='' style='max-width: 100%; height: auto;'/>\n";
      }
      this.input += "<!-- End Image -->\n";
      $.notify('Inserted', 'success');
    },
    addPost: function(e, submit) {
      e.preventDefault();
      var that = this;
      var $form = $("#postForm");
      if ( submit ) {
        if ( window.location.href.match(/posts\/new/) ) {
          var method = 'POST';
        } else {
          var method = 'PUT';
        }
        $.ajax({
          type: method,
          dataType: 'json',
          contentType: 'application/json',
          url: $form.attr('action'),
          data: JSON.stringify(that.getFormValues($form)),
          success: function(response) {
            $.notify('Post Saved', 'success');
            setTimeout(function(){
              if ( window.location.href.match(/posts\/new/) ) {
                window.location.href = '/statixite/sites/' + response.site_id + '/posts/' + response.id + '/edit';
              }
            }, 2000);
          },
          error: function(xhr, status, error) {
            if ( xhr.responseJSON.errors.title ) {
              $.notify('Title ' + xhr.responseJSON.errors.title[0], 'error');
            } else {
              $.notify('Something went wrong', 'error')
            }
          }
        });
      }
    },
    getFormValues: function($form){
      return {
        post: {
          type: 'Post',
          title: this.title,
          front_matter: this.front_matter,
          content: this.input
        }
      }
    }
  },
  computed: {
    domain: function() {
      if (this.video.url.indexOf("://") > -1) {
        videoDomain = this.video.url.split('/')[2];
      }
      else {
        videoDomain = this.video.url.split('/')[0];
      }
      videoDomain = videoDomain.split(':')[0];
      return videoDomain;
    },
    getSelectedText: function() {
        if (window.getSelection) {
            return window.getSelection().toString();
        } else if (document.selection) {
            return document.selection.createRange().text;
        }
        return '';
    },
    title: {
      get: function() {
        return this.front_matter.title;
      },
      set: function(newValue) {
        return newValue;
      }
    }
  },
  ready: function() {
    this.front_matter = $('#frontMatterData').data('front-matter');
    if ( this.front_matter.title == undefined ) {
      this.front_matter.title = "";
    }
    if ( this.front_matter.date == undefined ) {
      var today = new Date();
      this.front_matter.date = today.toISOString().slice(0,10);
    }
    if ( this.front_matter.layout == undefined ) {
      this.front_matter.layout = 'post';
    }
    jsonEditor.set(this.front_matter);
  }
})

