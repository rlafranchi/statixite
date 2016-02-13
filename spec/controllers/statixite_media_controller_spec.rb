require 'rails_helper'

describe Statixite::MediaController do
  routes { Statixite::Engine.routes }
  let(:site) { Fabricate(:site) }
  describe "GET #index" do
    it 'renders index' do
      get :index, :site_id => site.id
      expect(response).to render_template :index
    end
  end
  describe "POST #create" do
  end
  describe "DELETE #destroy" do
    let(:media) { Fabricate(:media, :site_id => site.id) }
  end
end
