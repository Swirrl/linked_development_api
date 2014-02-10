require 'spec_helper'

describe DocumentRepository do
  subject(:repository) { DocumentRepository.new }
  
  # The total number of each document type in the test dataset.
  let(:r4d_total) { SpecValues::TOTAL_R4D_DOCUMENTS }
  let(:eldis_total) { SpecValues::TOTAL_ELDIS_DOCUMENTS }
  
  describe '#get_one' do
    # Tests currently in document_service_spec.rb
    # TODO move some of those specs here
  end
  
  describe '#get_all' do 
    let(:eldis_id_pattern) { /http:\/\/linked-development\.org\/eldis\/output\/A[0-9]+\// }
    let(:r4d_id_pattern) { /http:\/\/linked-development.org\/r4d\/output\/[0-9]+\// }

    context 'eldis' do
      describe 'short' do 
        let(:document) { repository.get_all({type: 'eldis', detail: 'short'}, :limit => 10) }
        
        specify { expect(document.class).to be == Array }
        specify { expect(document.size).to be  == 10 }
        
        specify { expect(document[0]['linked_data_uri']).to match(eldis_id_pattern) }
      end
      
      describe 'full' do 
        let(:document) { repository.get_all({type: 'eldis', detail: 'full'}, :limit => 10) }
        
        specify { expect(document.class).to be == Array }
        specify { expect(document.size).to be  == 10 }
        
        specify { expect(document[0]['linked_data_uri']).to match(eldis_id_pattern) }
      end
    end

    context 'r4d' do
      describe 'short' do 
        let(:document) { repository.get_all({type: 'r4d', detail: 'short'}, :limit => 1) }

        specify { expect(document.class).to be == Array }
        specify { expect(document.size).to be  == 1 }
        
        specify { expect(document[0]['linked_data_uri']).to match(r4d_id_pattern) }
      end

      describe 'full' do 
        let(:document) { repository.get_all({type: 'r4d', detail: 'full'}, :limit => 3) }

        specify { expect(document.class).to be == Array }
        specify { expect(document.size).to be  == 3 }
        
        specify { expect(document[0]['linked_data_uri']).to match(r4d_id_pattern) }
      end
    end

    context 'all' do
      describe 'short' do 
        let(:document) { repository.get_all({type: 'all', detail: 'short'}, :limit => 10) }

        specify { expect(document.class).to be == Array }
        specify { expect(document.size).to be  == 10 }
        
        specify { expect(document[0]['linked_data_uri']).to match(eldis_id_pattern) }
      end

      describe 'full' do 
        let(:document) { repository.get_all({type: 'all', detail: 'full'}, :limit => 5) }

        specify { expect(document.class).to be == Array }
        specify { expect(document.size).to be  == 5 }
        
        specify { expect(document[0]['linked_data_uri']).to match(eldis_id_pattern) }
      end
    end
  end

  describe '#total_results_of_last_query' do 
    describe 'r4d' do
      specify { 
        repository.get_all({type: "r4d", detail: "full"}, :limit => 5)
        expect(repository.total_results_of_last_query ).to be r4d_total
      }
    end
    
    describe 'eldis' do
      specify { 
        repository.get_all({type: "eldis", detail: "full"}, :limit => 5)
        expect(repository.total_results_of_last_query ).to be == eldis_total
      }
    end

    describe 'all' do 
      specify { 
        results = repository.get_all({type: "all", detail: "full"}, :limit => 5) 
        
        expect(repository.total_results_of_last_query).to be == (eldis_total + r4d_total)
      }
    end
  end
  
  describe '#search' do
    let(:default_parameters) { {:host => 'test.host', :limit => 10, :offset => 0}  }

    describe 'iati identifier search' do
      # This one is r4d ONLY
      context 'r4d' do
        let(:response) { repository.search('r4d', {'iati-identifier' => 'GB-1-114192'}, 'full', default_parameters) }

        specify { expect(response.class).to be Array }
      end
    end
    
    describe 'free text search' do
      context 'r4d' do
        let(:response) { repository.search('r4d', {:q => 'linked'}, 'full', default_parameters) }
        specify { expect(response.class).to be Array }
      end
      
      context 'eldis' do
        let(:response) { repository.search('eldis', {:q => 'linked'}, 'full', default_parameters) }
        specify { expect(response.class).to be Array }
      end
      
      context 'all' do
        let(:response) { repository.search('all', {:q => 'linked'}, 'full', default_parameters) }
        specify { expect(response.class).to be Array }
      end
    end

    describe 'theme search' do
      let(:eldis_id_pattern) { /C[0-9]+/ }
      
      context 'r4d' do
        let(:response) { repository.search('r4d', {:theme => 'upgrading'}, 'full', default_parameters) }
        let(:object) { response.first }
        let(:child_object) { object['category_theme_array']['theme'].first }

        specify { expect(child_object['object_id'].class).to be String }
      end
      
      context 'eldis' do
        let(:response) { repository.search('eldis', {:theme => 'C782'}, 'full', default_parameters) }
        let(:object) { response.first }
        let(:child_object) { object['category_theme_array']['theme'].first }

        specify { expect(child_object['object_id']).to match(eldis_id_pattern) }
      end
      
      context 'all' do
        let(:response) { repository.search('all', {:theme => 'C782'}, 'full', default_parameters) }
        let(:object) { response.first }
        let(:child_object) { object['category_theme_array']['theme'].first }

        specify { expect(child_object['object_id']).to match(eldis_id_pattern) }
      end

      describe 'by name' do
        let(:response) { repository.search('eldis', {:theme => 'funding education'}, 'full', default_parameters) }
        let(:object) { response.first }
        let(:child_object) { object['category_theme_array']['theme'].first }

        specify { expect(child_object['object_id']).to match(eldis_id_pattern) }
      end
      
    end

    describe 'country code search' do
      let(:eldis_id_pattern) { /C[0-9]+/ }

      context 'r4d' do
        let(:response) { repository.search('r4d', {:country => 'GB'}, 'full', default_parameters) }
        let(:object) { response.first }
        let(:child_object) { object['category_theme_array']['theme'].first }

        specify { expect(child_object['object_id'].class).to be String }
      end
      
      context 'eldis' do
        let(:response) { repository.search('eldis', {:country => 'GB'}, 'full', default_parameters) }
        let(:object) { response.first }
        let(:child_object) { object['category_theme_array']['theme'].first }

        specify { expect(child_object['object_id']).to match(eldis_id_pattern) }
      end
      
      context 'all' do
        let(:response) { repository.search('all', {:country => 'GB'}, 'full', default_parameters) }

        let(:object) { response.first }
        let(:child_object) { object['category_theme_array']['theme'].first }

        specify { expect(child_object['object_id']).to match(eldis_id_pattern) }
      end
    end

    describe 'eldis country id search' do
      let(:eldis_id_pattern) { /C[0-9]+/ }

      context 'r4d' do
        specify { expect { repository.search('r4d', {:country => 'A1044'}, 'full', default_parameters) }.to raise_error LinkedDevelopmentError }
      end
      
      context 'eldis' do
        let(:response) { repository.search('eldis', {:country => 'GB'}, 'full', default_parameters) }
        let(:object) { response.first }
        let(:child_object) { object['category_theme_array']['theme'].first }

        specify { expect(child_object['object_id']).to match(eldis_id_pattern) }
      end
      
      context 'all' do
        let(:response) { repository.search('all', {:country => 'GB'}, 'full', default_parameters) }
        let(:object) { response.first }
        let(:child_object) { object['category_theme_array']['theme'].first }

        specify { expect(child_object['object_id']).to match(eldis_id_pattern) }
      end
    end
    
    describe 'combinable search criteria' do
      let(:eldis_id_pattern) { /C[0-9]+/ }

      context 'r4d' do
        let(:response) { repository.search('r4d', {:country => 'BD', :theme => 'Natural_Resources_Systems_Programme', :q => 'Resources'}, 'full', default_parameters) }
        let(:object) { response.first }
        let(:child_object) { object['category_theme_array']['theme'].first }

        specify { expect(child_object['object_id'].class).to be String }
      end
      
      context 'eldis' do
        let(:response) { repository.search('eldis', {:country => 'TW', :theme => 'C782', :q => 'facebook'}, 'full', default_parameters) }
        let(:object) { response.first }
        let(:child_object) { object['category_theme_array']['theme'].first }

        specify { expect(child_object['object_id']).to match(eldis_id_pattern) }

      end
      
      context 'all' do
        let(:response) { repository.search('all', {:country => 'GB', :theme => 'C782', :q => 'development'}, 'full', default_parameters) }
        let(:object) { response.first }
        let(:child_object) { object['category_theme_array']['theme'].first }

        specify { expect(child_object['object_id']).to match(eldis_id_pattern) }
      end
    end
  end

end
