require 'spec_helper'

describe GetController do 
  
  let(:service) { double('service') }
  
  describe 'GET themes' do 
    before :each do 
      ThemeService.stub(:build).and_return service
    end

    context 'errors' do
      it 'returns 404 on DocumentNotFound' do
        service.stub(:get).and_raise DocumentNotFound
        get :themes, graph: 'eldis', id: 'C9999999999999', detail: 'full', :format => :json
        expect(response.status).to be 404 
      end

      it 'returns 400 on LinkedDevelopmentError' do 
        service.stub(:get).and_raise LinkedDevelopmentError
        get :themes, graph: 'eldis', id: 'C9999999999999', detail: 'full', :format => :json
        expect(response.status).to be 400
      end
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

  describe 'GET countries' do 
    before :each do 
      CountryService.stub(:build).and_return service
    end

    it 'delegates to the CountryService' do
      service.should_receive(:get).with({type: 'eldis', id: 'A1036', detail: 'full'})
      get :countries, graph: 'eldis', id: 'A1036', detail: 'full', :format => :json
    end
  end
  
  describe 'GET regions' do 
    before :each do 
      RegionService.stub(:build).and_return service
    end

    it 'delegates to the CountryService' do
      service.should_receive(:get).with({type: 'eldis', id: 'C30', detail: 'full'})
      get :regions, graph: 'eldis', id: 'C30', detail: 'full', :format => :json
    end
  end

  describe 'GET research_outputs' do 
    before :each do 
      ResearchOutputService.stub(:build).and_return service
    end

    it 'delegates to the ResearchOutputService' do
      service.should_receive(:get).with({type: 'r4d', id: 'GB-1-112681', detail: 'full'})
      get :research_outputs, graph: 'r4d', id: 'GB-1-112681', detail: 'full', :format => :json
    end
  end
  
  pending 'content negotiation'

  after :each do 
    expect(response.headers['Content-Type']).to eq('application/json; charset=utf-8')
  end
end
