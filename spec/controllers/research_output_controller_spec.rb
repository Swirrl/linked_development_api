require 'spec_helper'

describe ResearchOutputController do 
  let(:service) { double('service') }

  describe 'GET #get' do 
    before :each do 
      ResearchOutputService.stub(:build).and_return service
    end

    it 'delegates to the ResearchOutputService' do
      service.should_receive(:get).with({type: 'r4d', id: 'GB-1-112681', detail: 'full'}, hash_including(:host => 'test.host'))
      get :get, graph: 'r4d', id: 'GB-1-112681', detail: 'full', :format => :json
    end
  end

  describe 'GET #get_all' do 
    before :each do 
      ResearchOutputService.stub(:build).and_return service
    end

    it 'delegates to the ResearchOutputService' do
      service.should_receive(:get_all).with({type: 'r4d', detail: 'full'}, hash_including(:host => 'test.host'))
      get :get_all, graph: 'r4d', detail: 'full', :format => :json
    end
  end
  
  
end
