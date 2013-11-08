LinkedDevelopmentApi::Application.routes.draw do
  scope '/openapi' do
    get '/:graph/get/documents/:id(/:detail)', to: 'get#documents'
  end
end
