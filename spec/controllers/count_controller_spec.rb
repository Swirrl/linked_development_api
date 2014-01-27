require 'spec_helper'

describe CountController do 

  let(:service) { double('service') }

  describe 'GET themes' do 
    before :each do 
      ThemeService.stub(:build).and_return service
    end

    it 'delegates to the ThemeService' do
      service.should_receive(:count)
      get :themes, graph: 'eldis', :format => :json
    end
  end
  
  describe 'GET regions' do 
    before :each do 
      RegionService.stub(:build).and_return service
    end

    it 'delegates to the RegionService' do
      service.should_receive(:count)
      get :regions, graph: 'eldis', :format => :json
    end
  end
  
  describe 'GET countries' do 
    before :each do
      CountryService.stub(:build).and_return service
    end

    it 'delegates to the CountryService' do
      service.should_receive(:count)
      get :countries, graph: 'eldis', :format => :json
    end
  end
  
end
