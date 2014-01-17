require 'spec_helper'

describe RegionService do 
  let(:service) { RegionService.build }

  context '#get' do 
    let(:service) { RegionService.new :repository => region_repository }
    subject(:region_repository) { double('region-repository') }

    before :each do 
      service.stub(:wrap_result).and_return [{}]
    end

    describe 'eldis' do 
      it 'receives #get_eldis when service is passed type of "eldis"' do 
        region_repository.should_receive(:get_eldis)
        service.get(type: 'eldis', id: 'C57', detail: 'short')
      end
    end

    describe 'r4d' do 
      it 'receives #get_r4d when service is passed type of "r4d"' do 
        region_repository.should_receive(:get_r4d)
        service.get(type: 'r4d', id: '057', detail: 'short')
      end
    end

    describe 'all' do 
      it 'receives #get_r4d when service is passed type of "r4d"' do 
        region_repository.should_receive(:get_r4d)
        service.get(type: 'r4d', id: '057', detail: 'short')
      end
      
      it 'receives #get_eldis when service is passed type "all" and id is eldis formatted' do 
        region_repository.should_receive(:get_eldis)
        service.get(type: 'all', id: 'C30', detail: 'short')
      end
    end
  end

  context '#get_all' do
    describe 'eldis' do 
      let(:document) { service.get_all({type: 'eldis', detail: 'short'}, :host => 'test.host', :limit => 40) }
      specify { expect(document['results'].class).to be Array }
      specify { expect(document['results'].length).to be SpecValues::TOTAL_ELDIS_REGIONS }
    end

    describe 'r4d' do
      let(:document) { service.get_all({type: 'r4d', detail: 'short'}, :host => 'test.host', :limit => 40) }
      specify { expect(document['results'].class).to be Array }
      specify { expect(document['results'].length).to be SpecValues::TOTAL_R4D_REGIONS }
    end

    describe 'all' do
      let(:document) { service.get_all({type: 'all', detail: 'short'}, :host => 'test.host', :limit => 40) }
      specify { expect(document['results'].class).to be Array }
      specify { expect(document['results'].length).to be SpecValues::TOTAL_REGIONS }
    end
  end    
  


  # describe 'integration specs' do
  #   context 'all' do 
  #     context "id: A1151 (eldis)" do
  #       include_examples 'example documents', [:all, :get, :country, 'A1151', {filename: 'eldis_get_country_A1151'}] # equivalent to eldis query
  #     end
  #   end
  # end

end
