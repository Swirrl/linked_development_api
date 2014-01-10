require 'spec_helper'

describe GetAllController do 
  
  let(:service) { double('service') }
  
  describe 'GET themes' do 
    before :each do 
      ThemeService.stub(:build).and_return service
    end

    it 'delegates to the ThemeService' do
      service.should_receive(:get_all).with({type: 'eldis', detail: 'full'}, hash_including(:host => 'test.host'))
      get :themes, graph: 'eldis', detail: 'full', :format => :json
    end
  end
  
  describe 'GET documents' do 
    before :each do 
      DocumentService.stub(:build).and_return service
    end

    it 'delegates to the ThemeService' do
      service.should_receive(:get_all).with({type: 'eldis', detail: 'full'}, hash_including(:host => 'test.host'))
      get :documents, graph: 'eldis', detail: 'full', :format => :json
    end
  end

  describe 'GET regions' do 
    pending
  end

  describe 'GET countries' do 
     pending
  end

  after :each do 
    expect(response.headers['Content-Type']).to eq('application/json; charset=utf-8')
  end
end
