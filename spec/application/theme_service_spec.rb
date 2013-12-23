require 'spec_helper'

describe ThemeService do
  let(:service) { ThemeService.build }

  context "#get" do 
    describe 'raises error' do 
      it 'InvalidDocumentType when type is not one of eldis, r4d, or all' do 
        expect {service.get type: 'foo', id: 'C782', detail: 'short'}.to raise_error InvalidDocumentType
      end
    end
    
    describe 'when type is all' do 
      let(:theme_repository) { double('theme-repository') }
      let(:service) { ThemeService.new :theme_repository => theme_repository }
      
      it 'an arbitrary id resolves to a dbpedia uri' do 
        expect(theme_repository).to receive(:run_r4d_query).with(hash_including(:resource_uri => "http://dbpedia.org/resource/lolkittens"))
        service.get type: 'all', id: 'lolkittens', detail: 'short'
      end

      it 'an :id of the form c_XXXX resolves to agrovoc uri' do
        expect(theme_repository).to receive(:run_r4d_query).with(hash_including :resource_uri => "http://aims.fao.org/aos/agrovoc/c_10176")
        service.get type: 'all', id: 'c_10176', detail: 'short'
      end

      it 'an :id of the form CXXX resolves to an eldis resource uri' do 
        expect(theme_repository).to receive(:run_eldis_query).with(hash_including :resource_uri => "http://linked-development.org/eldis/themes/C785/")
        service.get type: 'all', id: 'C785', detail: 'short'
      end
    end
    
    describe 'when type is eldis' do 
      let(:theme_repository) { double('theme-repository') }
      let(:service) { ThemeService.new :theme_repository => theme_repository }
      
      it 'an arbitrary id resolves raises an error' do 
        expect { service.get type: 'eldis', id: 'invalid_error', detail: 'short' }.to raise_error LinkedDevelopmentError
      end

      it 'an :id of the form CXXX resolves to an eldis resource uri' do 
        expect(theme_repository).to receive(:run_eldis_query).with(hash_including :resource_uri => "http://linked-development.org/eldis/themes/C785/")
        service.get type: 'eldis', id: 'C785', detail: 'short'
      end
    end

    describe 'when type is all' do 
      let(:theme_repository) { double('theme-repository') }
      let(:service) { ThemeService.new :theme_repository => theme_repository }
      
      it 'an arbitrary id resolves to a dbpedia uri' do 
        expect(theme_repository).to receive(:run_r4d_query).with(hash_including(:resource_uri => "http://dbpedia.org/resource/lolkittens"))
        service.get type: 'all', id: 'lolkittens', detail: 'short'
      end

      it 'an :id of the form c_XXXX resolves to agrovoc uri' do
        expect(theme_repository).to receive(:run_r4d_query).with(hash_including :resource_uri => "http://aims.fao.org/aos/agrovoc/c_10176")
        service.get type: 'all', id: 'c_10176', detail: 'short'
      end

      it 'an :id of the form CXXX resolves to an eldis resource uri' do 
        expect(theme_repository).to receive(:run_eldis_query).with(hash_including :resource_uri => "http://linked-development.org/eldis/themes/C785/")
        service.get type: 'all', id: 'C785', detail: 'short'
      end
    end
  end

  describe 'integration specs' do

    context 'all' do 
      context ":id C782 (r4d) (short)" do
        let(:response) { service.get(type: "all", id: "C782", detail: "short") }
        let(:document) { response["results"].first }
        
        describe "JSON output" do
          let(:json_output) { response.to_json }
          
          example "complete document" do
            expect(JSON.parse(json_output)).to be == sample_json("eldis_theme_C782_short.json")
          end
        end
      end

      context ":id C782 (r4d) (full)" do
        let(:response) { service.get(type: "all", id: "C782", detail: "full") }
        let(:document) { response["results"].first }
        
        describe "JSON output" do
          let(:json_output) { response.to_json }
          
          example "complete document" do
            expect(JSON.parse(json_output)).to be == sample_json("eldis_theme_C782_full.json")
          end
        end
      end

      context ":id knowledge_sharing (r4d/dbpedia) (short)" do
        let(:response) { service.get(type: "all", id: "knowledge_sharing", detail: "short") }
        let(:document) { response["results"].first }
        
        describe "JSON output" do
          let(:json_output) { response.to_json }
          
          example "complete document" do
            expect(JSON.parse(json_output)).to be == sample_json("all_theme_knowledge_sharing_short.json")
          end
        end
      end


    end

    context 'eldis' do
      context ":id C782 (short)" do
        let(:response) { service.get(type: "eldis", id: "C782", detail: "short") }
        let(:document) { response["results"].first }
        
        describe "JSON output" do
          let(:json_output) { response.to_json }
          
          example "complete document" do
            expect(JSON.parse(json_output)).to be == sample_json("eldis_theme_C782_short.json")
          end
        end
      end
      
      context ':id C782 (full)' do 
        let(:response) { service.get(type: "eldis", id: "C782", detail: "full") }
        let(:document) { response["results"].first }

        describe "JSON output" do
          let(:json_output) { response.to_json }
          
          example "complete document" do
            expect(JSON.parse(json_output)).to be == sample_json("eldis_theme_C782_full.json")
          end
        end
      end
    end

    context 'r4d' do
      context 'get c_10176 (full)' do 
        let(:response) { service.get(type: "r4d", :id => "c_10176", detail: "full") }
        let(:document) { response["results"].first }

        describe "JSON output" do
          let(:json_output) { response.to_json }
          
          example "complete document" do
            expect(JSON.parse(json_output)).to be == sample_json("r4d_theme_c_10176_full.json")
          end
        end
      end

      context 'get c_10176 (short)' do 
        let(:response) { service.get(type: "r4d", id: "c_10176", detail: "short") }
        let(:document) { response["results"].first }

        describe "JSON output" do
          let(:json_output) { response.to_json }
          
          example "complete document" do
            expect(JSON.parse(json_output)).to be == sample_json("r4d_theme_c_10176_short.json")
          end
        end
      end
    end
  end
end
