require 'spec_helper'

describe GetController do 
  
  let(:service) { double('document_service') }
  
  before :each do 
    DocumentService.stub(:build).and_return service
  end

  describe 'GET themes' do 
    pending
  end
  
  describe 'GET documents' do 
    it 'delegates to the DocumentService' do
      service.should_receive(:get).with({type: 'eldis', id: 'A21959', detail: 'full'})
      get :documents, graph: 'eldis', id: 'A21959', detail: 'full'
    end
  end

  describe 'GET regions' do 
    pending
  end

  describe 'GET countries' do 
     pending
  end

  pending 'content negotiation'

  after :each do 
    expect(response.headers['Content-Type']).to eq('application/json')
  end

end
