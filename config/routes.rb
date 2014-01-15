LinkedDevelopmentApi::Application.routes.draw do
  root :to => redirect('http://linked-development.org/')

  scope '/openapi' do
    
    # Consider making these routes default to a json view by supplying the argument .... defaults: {format: :json}
    
    get '/:graph/get/documents/:id(/:detail)', to: 'get#documents', as: :get_documents
    get '/:graph/get_all/documents(/:detail)', to: 'get_all#documents', as: :get_all_documents

    get '/:graph/get/themes/:id(/:detail)', to: 'get#themes', as: :get_themes
    get '/:graph/get_all/themes(/:detail)', to: 'get_all#themes', as: :get_all_themes

    get '/:graph/get/countries/:id(/:detail)', to: 'get#countries', as: :get_countries
    get '/:graph/get_all/countries(/:detail)', to: 'get_all#countries', as: :get_all_countries 

    get '/:graph/get/regions/:id(/:detail)', to: 'get#regions', as: :get_regions
    get '/:graph/get_all/regions(/:detail)', to: 'get_all#regions', as: :get_all_regions
  end
end
