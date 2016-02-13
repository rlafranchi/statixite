require 'rails_helper'

describe Statixite::SitesController do
  routes { Statixite::Engine.routes }
  describe 'GET #new' do
    context 'logged in' do
      it 'renders new template' do
        get :new
        expect(response).to render_template :new
      end
      it 'assigns site variable' do
        get :new
        expect(assigns(:site)).to be_instance_of(Statixite::Site)
        expect(assigns(:site)).to be_new_record
      end
      it 'assigns templates variable' do
        get :new
        templates = YAML.load_file Statixite::Engine.root.join("lib", "assets", "templates.yaml")
        templates = templates.select { |t| t["whitelisted"] == true }
        expect(assigns(:templates).count).to eq(templates.count)
      end
    end
  end
  describe 'POST #create' do
    context 'valid input' do
      before do
        result = double(:site, successful?: true)
        allow_any_instance_of(Statixite::SiteOperationService).to receive(:build_template).and_return(result)
      end
      it 'redirects to sites index page' do
        post :create, site: { site_name: 'statix' }
        expect(response).to redirect_to sites_path
      end
      it 'flashes notice' do
        post :create, site: { site_name: 'statix' }
        expect(flash[:success]).to eq("statix saved.")
      end
    end
    context 'invalid input' do
      before do
        result = double(:site, successful?: false, error_message: 'Error')
        allow_any_instance_of(Statixite::SiteOperationService).to receive(:build_template).and_return(result)
      end
      it 'renders new template' do
        post :create, site: { site_name: '' }
        expect(response).to render_template :new
      end
    end
  end
  describe "GET #index" do
    before do
      2.times do
        Fabricate(:site)
      end
    end
    context 'logged in' do
      it 'renders index template' do
        get :index
        expect(response).to render_template :index
      end
      it 'assigns sites variable' do
        get :index
        expect(assigns(:sites)).to match_array(Statixite::Site.all)
      end
    end
  end
  describe "GET #settings" do
    let(:site) { Fabricate(:site, :settings => { :title => 'Title' }) }
    it "assigns settings variable" do
      get :settings, id: site.id
      expect(assigns(:settings)).to eq(site.reload.settings)
    end
  end
  describe "PUT #update" do
    let(:site) { Fabricate(:site) }
    it "redirects to settings path" do
      put :update, id: site.id, :site => { :settings =>  { :title => "Site", :description => "Desc"} }, :format => 'json'
      expect(response).to be_success
    end
  end
  describe "DELETE #destroy" do
    let(:site) { Fabricate(:site) }
    it 'deactivates the site' do
      delete :destroy, :id => site.id
      expect(Statixite::Site.count).to eq(0)
      expect(File.exist?(Rails.root.join("sites", site.site_name))).to eq(false)
      expect(response).to redirect_to sites_path
    end
  end
end
