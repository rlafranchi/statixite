require 'rails_helper'

describe Statixite::DeploymentService do
  describe "#deploy" do
    context 'local' do
      let(:site) { Fabricate(:site, :site_name => 'stx-test1') }
      before do
        FileUtils.rm_rf(Dir[site.site_root_path])
        Statixite.setup do |config|
          config.deploy_sites_to = :local
        end
        Statixite::SiteOperationService.new(site).build_template
      end
      it "creates a deployment", :vcr do
        Statixite::DeploymentService.new(site).deploy
        expect(site.deployments.count).to eq(1)
      end
    end
    context 'github' do
      let(:site) { Fabricate(:site, :site_name => 'stx-test2') }
      before do
        FileUtils.rm_rf(Dir[site.site_root_path])
        Statixite.setup do |config|
          config.deploy_sites_to = :github
          config.github_user = "statixite"
          config.github_token = ENV["GITHUB_TOKEN"]
        end
        Statixite::SiteOperationService.new(site).build_template
      end
      it "creates a deployment", :vcr do
        Statixite::DeploymentService.new(site).deploy
        expect{ Git.ls_remote("https://github.com/statixite/statixite-#{site.site_name}.git") }.not_to raise_error
      end
    end
    context 'rackspace' do
      let(:site) { Fabricate(:site, :site_name => 'stx-test3') }
      before do
        FileUtils.rm_rf(Dir[site.site_root_path])
        Statixite.setup do |config|
          config.deploy_sites_to = :fog
          config.fog_credentials = {
            :provider                 => 'Rackspace',
            :rackspace_username  => ENV['RACKSPACE_USERNAME'],
            :rackspace_api_key   => ENV['RACKSPACE_API_KEY'],
            :rackspace_region    => :dfw
          }
        end
        Statixite::SiteOperationService.new(site).build_template
      end
      it "saves the deploys hostname", :vcr do
        Statixite::DeploymentService.new(site).deploy
        expect(site.deployments.count).to eq(1)
        expect(site.hostname).to match(/rackcdn/)
      end
    end
  end
end
