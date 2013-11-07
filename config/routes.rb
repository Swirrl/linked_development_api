LinkedDevelopmentApi::Application.routes.draw do
  scope '/openapi' do
    get '/:graph/get/documents/:id/full', to: 'get#documents'
  end
end
