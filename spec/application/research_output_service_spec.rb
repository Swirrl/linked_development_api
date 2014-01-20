require 'spec_helper'

describe ResearchOutputService do 

  let(:service) { ResearchOutputService.build }

  context "#get" do 
    describe 'raises error' do 
      it 'InvalidDocumentType when graph type is not one of r4d, or all' do 
        expect {service.get type: 'foo', id: 'FOOBAR-1', detail: 'short'}.to raise_error InvalidDocumentType
        expect {service.get type: 'eldis', id: 'FOOBAR-1', detail: 'short'}.to raise_error InvalidDocumentType        
      end

      it 'LinkedDevelopmentError when detail is not short/full or nil' do 
        expect {service.get type: 'r4d', id: 'GB-1-112681', detail: 'foo'}.to raise_error LinkedDevelopmentError
      end

      it 'DocumentNotFound' do 
        expect {service.get type: 'r4d', id: 'GB-9-999999', detail: 'short'}.to raise_error DocumentNotFound
      end
    end
    
    describe 'when type is eldis' do 
      let(:research_repository) { double('theme-repository') }
      let(:service) { ResearchOutputService.new :repository => research_repository }
    end
    
    describe 'when type is r4d' do 
      let(:research_repository) { double('theme-repository') }
      let(:service) { ResearchOutputService.new :repository => research_repository }
    end

    describe 'when type is all' do 
    
    end
  end

end
