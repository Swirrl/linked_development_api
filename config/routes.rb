LinkedDevelopmentApi::Application.routes.draw do
  scope '/openapi' do
    get '/:graph/get/documents/:id(/:detail)', to: 'get#documents'
    get '/:graph/get/themes/:id(/:detail)', to: 'get#themes'
  end
end
