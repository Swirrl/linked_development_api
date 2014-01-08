LinkedDevelopmentApi::Application.routes.draw do
  root :to => redirect('http://linked-development.org/')

  scope '/openapi' do
    get '/:graph/get/documents/:id(/:detail)', to: 'get#documents'
    get '/:graph/get_all/documents(/:detail)', to: 'get_all#documents'

    get '/:graph/get/themes/:id(/:detail)', to: 'get#themes'
    get '/:graph/get_all/themes(/:detail)', to: 'get_all#themes'
  end
end
