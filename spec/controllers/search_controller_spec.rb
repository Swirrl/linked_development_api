require 'spec_helper'

describe SearchController do

  let(:service) { double('service') }

  before :each do 
    DocumentService.stub(:build).and_return service
  end
  
  describe 'GET search' do

    context 'with no search parameters' do
      before :each do
        get :search, :graph => 'r4d', :detail => 'full', :format => 'json'
      end
      
      it 'responds 400' do
        expect(response.status).to eq 400
      end
    end

    describe 'delegates to DocumentService#search' do
      subject { service }
      let(:search_parameters) { hash_including(:q, :theme, :country) }
      let(:pagination_parameters) { hash_including(:host, :limit, :offset) }
      
      specify { expect(service).to receive(:search).with('r4d', search_parameters, 'full', pagination_parameters) }

      after :each do
        get :search, :graph => 'r4d', :detail => 'full', :format => 'json', :q => 'free text query', :theme => 'C782', :country => 'UK'
      end
    end
  end
end
