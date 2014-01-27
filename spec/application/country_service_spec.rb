require 'spec_helper'

describe CountryService do 

  let(:service) { CountryService.build }

  context "#get" do 
    describe 'raises error' do 
      it 'InvalidDocumentType when graph type is not one of eldis, r4d, or all' do 
        expect {service.get type: 'foo', id: 'A1151', detail: 'short'}.to raise_error InvalidDocumentType
      end

      it 'LinkedDevelopmentError when detail is not short/full or nil' do 
        expect {service.get type: 'eldis', id: 'A1151', detail: 'foo'}.to raise_error LinkedDevelopmentError
      end

      it 'DocumentNotFound' do 
        expect {service.get type: 'eldis', id: 'C9999999999999', detail: 'short'}.to raise_error DocumentNotFound
      end
    end
    
    describe 'when type is eldis' do 
      let(:theme_repository) { double('theme-repository') }
      let(:service) { ThemeService.new :repository => theme_repository }
    end
    
    describe 'when type is r4d' do 
      let(:theme_repository) { double('theme-repository') }
      let(:service) { ThemeService.new :repository => theme_repository }
    end

    describe 'when type is all' do 
    
    end
  end

  describe 'integration specs' do
    context 'all' do 
      context "id: A1151 (eldis)" do
        include_examples 'example documents', [:all, :get, :country, 'A1151', {filename: 'eldis_get_country_A1151'}] # equivalent to eldis query
      end

      context "Turkey (fao/slug_id)" do
        include_examples 'example documents', [:all, :get, :country, 'Turkey', {filename: "r4d_get_country_Turkey"}] # equivalent to r4d query
      end
    end
  end

  # get_all

  context "#get_all" do 
    describe 'raises error' do 
      it 'InvalidDocumentType when type is not one of eldis, r4d, or all' do 
        expect {service.get_all({type: 'foo', detail: 'short'}, {:host => 'test.host'})}.to raise_error InvalidDocumentType
      end
    end

    context 'eldis' do 
      pending
    end
    
    context 'r4d' do
      pending
    end
    
    context 'all' do 
      pending
    end
  end

  # count
  
  context '#count' do
    let(:repository) { double('repository') }
    let(:service) { ThemeService.new :repository => repository } 
    
    context 'raises error on invalid graph type' do
      specify { expect { service.count({:type => 'foo'}, {:host => 'test.host'}) }.to raise_error InvalidDocumentType }
    end

    it 'delegates to repository' do
      repository.should_receive(:count).with('r4d', an_instance_of(Hash))
      repository.should_receive(:total_results_of_count_query).and_return 10
      service.count({:type => 'r4d'}, {:host => 'test.host'})
    end
  end

end
