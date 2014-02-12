require 'spec_helper'

describe GetChildrenController do
  
  let(:service) { double('service') }

  describe 'GET themes' do
    before :each do 
      ThemeService.stub(:build).and_return service
    end
    
    it 'delegates to the DocumentService' do
      service.should_receive(:get_children).with({type: 'eldis', id: 'C782', detail: 'full'}, instance_of(Hash))

      get :themes, graph: 'eldis', id: 'C782', detail: 'full', :format => :json
    end
  end
end
