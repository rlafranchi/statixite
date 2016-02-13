require 'rails_helper'

describe Statixite::DeploymentsController do
  routes { Statixite::Engine.routes }
  describe "GET #index" do
    let(:site) { Fabricate(:site, build_option: 'scratch') }
    it 'renders index template' do
      get :index, site_id: site.id
      expect(response).to render_template :index
    end
    it 'assigns site variable' do
      get :index, site_id: site.id
      expect(assigns(:site)).to be_instance_of(Statixite::Site)
    end
  end
  describe "POST #create" do
    context 'successful' do
      before do
        result = double(:site, successful?: true)
        allow_any_instance_of(Statixite::DeploymentService).to receive(:deploy).and_return(result)
      end
      let(:site) { Fabricate(:site, build_option: 'scratch') }
      it "redirects to deployment path" do
        post :create, site: { domain_name: '' }, site_id: site.id
        expect(response).to redirect_to site_deployments_path(site)
      end
    end
    context 'unsuccessful' do
      before do
        result = double(:site, successful?: false, :error_message => 'Error')
        allow_any_instance_of(Statixite::DeploymentService).to receive(:deploy).and_return(result)
      end
      let(:site) { Fabricate(:site, build_option: 'scratch') }
      it "redirects to deployments path" do
        post :create, site: { domain_name: '' }, site_id: site.id
        expect(response).to redirect_to site_deployments_path(site)
      end
      it "flashes error", :vcr do
        post :create, site: { domain_name: '' }, site_id: site.id
        expect(flash[:alert]).to be_present
      end
    end
  end
  describe "GET #export", :vcr do
    let(:site) { Fabricate(:site, site_name: 'test') }
    before do
      Statixite.setup do |config|
        config.deploy_sites_to = :local
      end
      Statixite::SiteOperationService.new(site).build_template
      post :create, site: { domain_name: '' }, site_id: site.id
      get :export, site_id: site.id, deployment_id: site.reload.deployments.first.id, format: :zip
    end
    it "responds successfully" do
      expect(response.status).to eq(200)
    end
  end
end
