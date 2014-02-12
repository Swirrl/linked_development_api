require 'spec_helper'

describe ThemeService do
  let(:service) { ThemeService.build }
  let(:dummy_document) { {} }

  # The total number of each document type in the test dataset.
  let(:r4d_total) { SpecValues::TOTAL_R4D_THEMES }
  let(:eldis_total) { SpecValues::TOTAL_ELDIS_THEMES }

  context "#get" do 
    describe 'raises error' do 
      it 'InvalidDocumentType when type is not one of eldis, r4d, or all' do 
        expect {service.get type: 'foo', id: 'C782', detail: 'short'}.to raise_error InvalidDocumentType
      end

      it 'LinkedDevelopmentError when detail is not short/full or nil' do 
        expect {service.get type: 'eldis', id: 'C782', detail: 'foo'}.to raise_error LinkedDevelopmentError
      end

      it 'DocumentNotFound' do 
        expect {service.get type: 'eldis', id: 'C9999999999999', detail: 'short'}.to raise_error DocumentNotFound
      end
    end
    
    
    describe 'when type is all' do 
      let(:theme_repository) { double('theme-repository') }
      let(:service) { ThemeService.new :repository => theme_repository }
      it 'an arbitrary id resolves to a dbpedia uri' do 
        expect(theme_repository).to receive(:get_r4d).with(hash_including(:resource_uri => "http://dbpedia.org/resource/lolkittens")).and_return dummy_document
        service.get type: 'all', id: 'lolkittens', detail: 'short'
      end

      it 'an :id of the form c_XXXX resolves to agrovoc uri' do
        expect(theme_repository).to receive(:get_r4d).with(hash_including :resource_uri => "http://aims.fao.org/aos/agrovoc/c_10176").and_return dummy_document
        service.get type: 'all', id: 'c_10176', detail: 'short'
      end

      it 'an :id of the form CXXX resolves to an eldis resource uri' do 
        expect(theme_repository).to receive(:get_eldis).with(hash_including :resource_uri => "http://linked-development.org/eldis/themes/C785/").and_return dummy_document
        service.get type: 'all', id: 'C785', detail: 'short'
      end
    end
    
    describe 'when type is eldis' do 
      let(:theme_repository) { double('theme-repository') }
      let(:service) { ThemeService.new :repository => theme_repository }
      
      it 'an arbitrary id resolves raises an error' do 
        expect { service.get type: 'eldis', id: 'invalid_error', detail: 'short' }.to raise_error LinkedDevelopmentError
      end

      it 'an :id of the form CXXX resolves to an eldis resource uri' do 
        expect(theme_repository).to receive(:get_eldis).with(hash_including :resource_uri => "http://linked-development.org/eldis/themes/C785/").and_return dummy_document
        service.get type: 'eldis', id: 'C785', detail: 'short'
      end
    end

    describe 'when type is all' do 
      let(:theme_repository) { double('theme-repository') }
      let(:service) { ThemeService.new :repository => theme_repository }
      
      it 'an arbitrary id resolves to a dbpedia uri' do 
        expect(theme_repository).to receive(:get_r4d).with(hash_including(:resource_uri => "http://dbpedia.org/resource/lolkittens")).and_return dummy_document
        service.get type: 'all', id: 'lolkittens', detail: 'short'
      end

      it 'an :id of the form c_XXXX resolves to agrovoc uri' do
        expect(theme_repository).to receive(:get_r4d).with(hash_including :resource_uri => "http://aims.fao.org/aos/agrovoc/c_10176").and_return dummy_document
        service.get type: 'all', id: 'c_10176', detail: 'short'
      end

      it 'an :id of the form CXXX resolves to an eldis resource uri' do 
        expect(theme_repository).to receive(:get_eldis).with(hash_including :resource_uri => "http://linked-development.org/eldis/themes/C785/").and_return dummy_document
        service.get type: 'all', id: 'C785', detail: 'short'
      end
    end
  end

  describe 'integration specs' do
    context 'all' do 
      context "id: C782 (eldis)" do
        include_examples 'example documents', [:all, :get, :theme, 'C782', {filename: 'eldis_get_theme_C782'}] # equivalent to eldis query
      end

      context "knowledge_sharing (r4d/dbpedia)" do
        include_examples 'example documents', [:all, :get, :theme, 'knowledge_sharing', {filename: "r4d_get_theme_knowledge_sharing"}] # equivalent to r4d query
      end
    end

    context 'eldis' do
      context "id: C782" do
        include_examples 'example documents', [:eldis, :get, :theme, 'C782']
      end
    end

    context 'r4d' do
      context 'id: c_10176' do 
        include_examples 'example documents', [:r4d, :get, :theme, 'c_10176']
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
      include_examples 'example documents', [:eldis, :get_all, :theme, {:limit => 10, :offset => 0, :host => 'test.host'}, {:filename => 'eldis_get_all_theme'}]
    end
    
    context 'r4d' do
      include_examples 'example documents', [:r4d, :get_all, :theme, {:limit => 10, :offset => 0, :host => 'test.host'}, {:filename => 'r4d_get_all_theme'}]
    end
    
    context 'all' do 
      context 'short' do 
        let(:response) { service.get_all(type: 'eldis', detail: 'short') }
      
        let(:json_output) { response.to_json }
        example "matches example document" do
          pending 'TODO'
        
          expect(JSON.parse(json_output)).to be == sample_json("eldis_get_all_theme_short.json")
        end
      end
      
      context 'full'
    end
  end

  # count
  
  context '#count' do
    let(:repository) { double('repository') }
    let(:service) { ThemeService.new :repository => repository } 
    
    context 'raises error on invalid graph type' do
      specify { expect { service.count({:type => 'foo'}, {:host => 'test.host'}) }.to raise_error InvalidDocumentType }
    end

    describe 'calls repository' do
      before :each do
        repository.stub(:count)
        repository.stub(:total_results_of_count_query).and_return 10
      end

      it '#count' do
        expect(repository).to receive(:count).with('r4d', an_instance_of(Hash))
        service.count({:type =>'r4d'}, {:host => 'test.host'})        
      end

      it '#total_results_of_count_query' do
        expect(repository).to receive(:total_results_of_count_query).and_return 10
        service.count({:type =>'r4d'}, {:host => 'test.host'})
      end
    end
  end

  context "#get_children" do 
    describe 'raises error' do 
      it 'InvalidDocumentType when type is not eldis or all' do 
        expect { service.get_children({type: 'r4d', id: 'C782', detail: 'short'}, {:host => 'test.host'}) }.to raise_error InvalidDocumentType
      end
    end
    
    describe 'eldis' do
      pending
    end
  end
end
