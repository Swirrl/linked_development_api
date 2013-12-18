require 'spec_helper'

describe GetController do 
  
  let(:service) { double('service') }
  
  describe 'GET themes' do 
    before :each do 
      ThemeService.stub(:build).and_return service
    end

    it 'delegates to the ThemeService' do
      service.should_receive(:get).with({type: 'eldis', id: 'C782', detail: 'full'})
      get :themes, graph: 'eldis', id: 'C782', detail: 'full', :format => :json
    end
  end
  
  describe 'GET documents' do 
    before :each do 
      DocumentService.stub(:build).and_return service
    end

    it 'delegates to the DocumentService' do
      service.should_receive(:get).with({type: 'eldis', id: 'A21959', detail: 'full'})
      get :documents, graph: 'eldis', id: 'A21959', detail: 'full', :format => :json
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
    expect(response.headers['Content-Type']).to eq('application/json; charset=utf-8')
  end

end
