require 'spec_helper'

describe DocumentRepository do
  subject(:repository) { DocumentRepository.new }
  
  # The total number of each document type in the test dataset.
  let(:r4d_total) { 34509 }
  let(:eldis_total) { 37515 }
  
  describe '#get' do
    # Tests currently in document_service_spec.rb
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
end
