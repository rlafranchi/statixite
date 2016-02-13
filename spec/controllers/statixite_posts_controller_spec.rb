require 'rails_helper'

describe Statixite::PostsController do
  routes { Statixite::Engine.routes }
  let(:site) { Fabricate(:site) }
  before do
    Statixite::SiteOperationService.new(site).build_template
  end
  describe 'GET #new' do
    it 'renders new template' do
      get :new, site_id: site.id
      expect(response).to render_template :new
    end
    it 'sets new post record' do
      get :new, site_id: site.id
      expect(assigns(:post)).to be_new_record
      expect(assigns(:post)).to be_instance_of(Statixite::Post)
    end
  end
  describe 'POST #create' do
    let(:post_data) {
      {
        title: 'Title',
        categories: ['tag', 'cat', 'dog'],
        date: '2015-01-01',
        hash_data: {
          key: 'value',
          other_key: 'other_value'
        }
      }
    }
    context 'valid input' do
      it 'responds successfully' do
        post :create, site_id: site.id, post: {title: 'Title', content: "# Heading/n**Bold**", front_matter: post_data}, :format => 'json'
        expect(response.status).to eq(200)
      end
      it 'saves the post' do
        post :create, site_id: site.id, post: {title: 'Title', content: "# Heading/n**Bold**", front_matter: post_data }, :format => 'json'
        expect(Statixite::Post.count).to eq(2)
      end
      it 'writes the post' do
        post :create, site_id: site.id, post: {title: 'Title', content: "# Heading/n**Bold**", front_matter: post_data }, :format => 'json'
        expect(File.open(Statixite::Post.where(title: 'Title').first.post_pathname)).to_not be_nil
      end
      it 'builds config' do
        post :create, site_id: site.id, post: {title: 'Title', content: "# Heading\n**Bold**", front_matter: post_data }, :format => 'json'
        line_two = IO.readlines(Statixite::Post.where(title: 'Title').first.post_pathname)[1]
        expect(line_two).to eq("title: Title\n")
      end
      it 'stores config' do
        post :create, site_id: site.id, post: {title: 'Title', content: "# Heading\n**Bold**", front_matter: post_data }, :format => 'json'
        expect(Statixite::Post.where(title: 'Title').first.front_matter["title"]).to eq(post_data[:title])
      end
      it 'slugifies title' do
        post :create, site_id: site.id, post: {title: 'Title samp', content: "# Heading\n**Bold**", front_matter: post_data }, :format => 'json'
        expect(Statixite::Post.where(title: 'Title samp').first.reload.post_pathname.basename.to_s).to include("title-samp")
      end
      it 'slugifies title with suffix if file exists' do
        Fabricate(:post, title: 'Title samp', site_id: site.id, front_matter: { title: 'Title samp', date: '2015-06-25' })
        Fabricate(:post, title: 'Title samp', site_id: site.id, front_matter: { title: 'Title samp', date: '2015-06-25' })
        Fabricate(:post, title: 'Title samp', site_id: site.id, front_matter: { title: 'Title samp', date: '2015-06-25' })
        post :create, site_id: site.id, post: {title: 'Title samp', content: "# Heading\n**Bold**", front_matter: post_data }, :format => 'json'
        expect(Statixite::Post.where(title: 'Title samp')[2].reload.post_pathname.basename.to_s).to include("title-samp-2")
      end
      it 'writes correct layout' do
        post :create, site_id: site.id, post: {title: 'Title', content: "# Heading\n**Bold**\n", front_matter: { title: 'Title', date: '2015-06-25'} }, :format => 'json'
        expect(Statixite::Post.last.front_matter['layout']).to eq("post")
      end
    end
    context 'invalid input' do
      it 'responds with error' do
        post :create, site_id: site.id, post: {title: '', content: "# Heading\n**Bold**\n", front_matter: post_data }, :format => 'json'
        expect(response.status).to eq(500)
      end
    end
  end
  describe 'GET #edit' do
    let(:post) { Fabricate(:post, site_id: site.id) }
    it 'renders edit page' do
      get :edit, site_id: site.id, id: post.id
      expect(response).to render_template :edit
    end
  end
  describe 'GET #index' do
    before do
      3.times do
        Fabricate(:post, site_id: site.id)
      end
    end
    it 'renders index template' do
      get :index, site_id: site.id
      expect(response).to render_template :index
    end
    it 'only displays posts' do
      get :index, site_id: site.id
      expect(assigns(:posts).count).to eq(4)
    end
  end
  describe 'PUT #update' do
    let(:post) { Fabricate(:post, title: 'title', content: 'content', site_id: site.id, front_matter: { title: 'title', date: '2015-05-05' }) }
    context 'valid input' do
      it 'responds successfully' do
        put :update, id: post.id, site_id: site.id, post: { title: 'new title', front_matter: { title: 'new title', date: '2015-05-05' } }, :format => 'json'
        expect(response.status).to eq(200)
      end
      it 'updates the post' do
        put :update, id: post.id, site_id: site.id, post: { title: 'new title', front_matter: { title: 'new title', date: '2015-05-05' } }, :format => 'json'
        expect(post.reload.title).to eq('new title')
      end
      it 'deletes old file on update' do
        old_file = post.post_pathname
        put :update, id: post.id, site_id: site.id, post: { title: 'new title', content: 'content', front_matter: { title: 'new title', "date": "2015-06-25" } }, :format => 'json'
        expect(File.exist?(old_file)).to eq(false)
      end
    end
    context 'invalid input' do
      it 'renders edit template' do
        put :update, id: post.id, site_id: site.id, post: { title: '', content: 'content' }, :format => 'json'
        expect(response.status).to eq(500)
      end
    end
  end
end
