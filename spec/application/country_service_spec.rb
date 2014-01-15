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

    # context 'eldis' do
    #   context "id: C782" do
    #     include_examples 'example documents', [:eldis, :get, :theme, 'C782']
    #   end
    # end

    # context 'r4d' do
    #   context 'id: c_10176' do 
    #     include_examples 'example documents', [:r4d, :get, :theme, 'c_10176']
    #   end
    # end
  end

  # get_all

  context "#get_all" do 
    describe 'raises error' do 
      it 'InvalidDocumentType when type is not one of eldis, r4d, or all' do 
        expect {service.get_all({type: 'foo', detail: 'short'}, {:host => 'test.host'})}.to raise_error InvalidDocumentType
      end
    end

    context 'eldis' do 
      #include_examples 'example documents', [:eldis, :get_all, :theme, {:limit => 10, :offset => 0, :host => 'test.host'}, {:filename => 'eldis_get_all_theme'}]
    end
    
    context 'r4d' do
      #include_examples 'example documents', [:r4d, :get_all, :theme, {:limit => 10, :offset => 0, :host => 'test.host'}, {:filename => 'r4d_get_all_theme'}]
    end
    
    # context 'all' do 
    #   context 'short' do 
    #     let(:response) { service.get_all(type: 'eldis', detail: 'short') }
      
    #     let(:json_output) { response.to_json }
    #     example "matches example document" do
    #       pending 'TODO'
        
    #       expect(JSON.parse(json_output)).to be == sample_json("eldis_get_all_theme_short.json")
    #     end
    #   end
      
    #   context 'full'
    # end
  end
end
