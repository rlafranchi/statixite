Statixite::Engine.routes.draw do
  resources :sites do
    member do
      get :settings
      get :build_and_preview
      post :preview_credentials
    end
    collection do
      get :repo_branches
    end
    get :template, to: 'templates#edit'
    post :template, to: 'templates#update'
    post :template_upload, to: 'templates#upload_files'
    delete :template_delete, to: 'templates#destroy'
    get :preview_config, to: 'config#preview_config'
    resources :posts, only: [:new, :create, :edit, :update, :index, :show]
    resources :deployments, only: [:index, :create] do
      get :export, to: 'deployments#export'
    end
    resources :media, only: [:create, :index, :destroy]
  end
  get 'sites/:site_name/clone/statixite/uploads/:id/:file_name', to: 'media#show'
  get 'uploads/:id/:file_name', to: 'media#show'
end
