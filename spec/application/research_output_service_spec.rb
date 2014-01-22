require 'spec_helper'

describe ResearchOutputService do 

  let(:service) { ResearchOutputService.build }

  let(:host_data) { {:host => 'test.local'} }
  
  context "#get" do 
    describe 'raises error' do 
      it 'InvalidDocumentType when graph type is not one of r4d, or all' do 
        expect {service.get({type: 'foo', id: 'FOOBAR-1', detail: 'short'}, host_data)}.to raise_error InvalidDocumentType
        expect {service.get({type: 'eldis', id: 'FOOBAR-1', detail: 'short'}, host_data)}.to raise_error InvalidDocumentType        
      end

      it 'LinkedDevelopmentError when detail is not short/full or nil' do 
        expect {service.get({type: 'r4d', id: 'GB-1-112681', detail: 'foo'}, host_data)}.to raise_error LinkedDevelopmentError
      end
    end

    describe 'when no matches are found' do
      # As multiple documents are expected back for a get on
      # ResearchOutputService we do not display an error like in other
      # cases, and simply return an empty array of results.
      
      let(:expected_result) { {"results"=>[], "metadata"=>{"num_results"=>0, "start_offset"=>0}  } }
      specify { expect(service.get({type: 'r4d', id: 'GB-NOSUCHDOCUMENT', detail: 'short'}, host_data)).to eq(expected_result) }
    end
    
    describe 'when type is eldis' do 
      let(:research_repository) { double('theme-repository') }
      let(:service) { ResearchOutputService.new :repository => research_repository }

      it 'should raise an error' do
        # eldis is not supported for research_outputs
        expect {service.get({type: 'eldis', id: 'GB-1-112681', detail: 'short'}, host_data)}.to raise_error LinkedDevelopmentError
      end
      
    end
    
    describe 'when type is r4d' do 
      let(:research_repository) { double('theme-repository') }
      let(:service) { ResearchOutputService.new :repository => research_repository }
    end

    describe 'when type is all' do 
    
    end
  end

end
