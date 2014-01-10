LinkedDevelopmentApi::Application.routes.draw do
  root :to => redirect('http://linked-development.org/')

  scope '/openapi' do
    get '/:graph/get/documents/:id(/:detail)', to: 'get#documents', as: :get_documents
    get '/:graph/get_all/documents(/:detail)', to: 'get_all#documents', as: :get_all_documents

    get '/:graph/get/themes/:id(/:detail)', to: 'get#themes', as: :get_themes
    get '/:graph/get_all/themes(/:detail)', to: 'get_all#themes', as: :get_all_themes
  end
end
