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

    get '/:graph/get/research_outputs/:id(/:detail)', to: 'research_output#get', as: :get_research_outputs
    get '/:graph/get_all/research_outputs(/:detail)', to: 'research_output#get_all', as: :get_all_research_outputs

    # In order to conform to the API these URI patterns do not follow
    # Rails conventions and are singular (e.g. theme not themes)
    get '/:graph/count/documents/theme', to: 'count#themes', as: :count_themes
    get '/:graph/count/documents/region', to: 'count#regions', as: :count_regions
    get '/:graph/count/documents/country', to: 'count#countries', as: :count_countries

    get '/:graph/get_children/themes/:id(/:detail)', to: 'get_children#themes', as: :get_children_themes
    
    # All searches are handled by this route.
    get '/:graph/search/documents(/:detail)', to: 'search#search', as: :search_documents
    
  end

  match "/404", to: "errors#not_found"
  match "/500", to: "errors#error"    
end
