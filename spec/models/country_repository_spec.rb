require 'spec_helper'

describe CountryRepository do 
  let(:country_uri_regex) { /http:\/\/linked-development\.org\/eldis\/geography\/A[0-9]+\// }
  let(:fao_regex) { /http:\/\/www.fao.org\/countryprofiles\/geoinfo\/geopolitical\/resource\/.*/ }

  subject(:repository) { CountryRepository.new }

  describe '#get_one' do
    let(:country_A1151) { "http://linked-development.org/eldis/geography/A1151/" }

    context 'no such id' do 
      let(:document) { repository.get_one(type: "eldis", resource_uri: "http://doesntexist.com/", detail: "full") }
      
      specify { expect(document).to be nil }
    end
    
    context 'eldis' do 
      describe "document C782" do 
        describe 'short' do 
          let(:document) { repository.get_one(type: "eldis", resource_uri: country_A1151, detail: "short") }
          
          specify { expect(document["linked_data_uri"]).to be    == country_A1151 }
          specify { expect(document["object_id"]).to be          == "A1151" }
          specify { expect(document["object_type"]).to be          == "country" }
          specify { expect(document["title"]).to be          == "Nauru" }
          specify { expect(document["metadata_url"]).to be          == "http://linked-development.org/openapi/eldis/get/countries/A1151/full" }

        end
        
        describe 'full' do 
          # Full on the linked-development PHP API for countries is the same as short
          let(:document) { repository.get_one(type: "eldis", resource_uri: country_A1151, detail: "full") }
          
          specify { expect(document["linked_data_uri"]).to be    == country_A1151 }
          specify { expect(document["object_id"]).to be          == "A1151" }
          specify { expect(document["object_type"]).to be          == "country" }
          specify { expect(document["title"]).to be          == "Nauru" }
          specify { expect(document["metadata_url"]).to be          == "http://linked-development.org/openapi/eldis/get/countries/A1151/full" }
        end

      end
    end
    
    context 'r4d' do
      describe "country (Turkey/fao slug)" do 
        describe 'full' do 
          let(:document) { repository.get_one(type: "r4d", :resource_uri => "http://www.fao.org/countryprofiles/geoinfo/geopolitical/resource/Turkey", detail: "full") }

          specify { expect(document["linked_data_uri"]).to be    == "http://www.fao.org/countryprofiles/geoinfo/geopolitical/resource/Turkey" }
          specify { expect(document["object_id"]).to be == "Turkey" }
          specify { expect(document["object_type"]).to be == "country" }
          specify { expect(document["title"]).to be == "Turkey" }
          specify { expect(document["metadata_url"]).to be == "http://linked-development.org/openapi/r4d/get/countries/Turkey/full" }
        end
       
        describe 'short' do 
          let(:document) { repository.get_one(type: "r4d", :resource_uri => "http://www.fao.org/countryprofiles/geoinfo/geopolitical/resource/Turkey", detail: "short") }

          specify { expect(document["linked_data_uri"]).to be    == "http://www.fao.org/countryprofiles/geoinfo/geopolitical/resource/Turkey" }
          specify { expect(document["object_id"]).to be == "Turkey" }
          specify { expect(document["object_type"]).to be == "country" }
          specify { expect(document["title"]).to be == "Turkey" }
          specify { expect(document["metadata_url"]).to be == "http://linked-development.org/openapi/r4d/get/countries/Turkey/full" }
        end
      end
    end
  end


  describe '#get_all' do 
    # some rubbish, minimal tests... but then this stuff is awkward & brittle to test.

    context 'eldis' do
      describe 'short' do 
        let(:document) { repository.get_all({type: 'eldis', detail: 'short'}, :limit => 20) }

        specify { expect(document.class).to be == Array }
        specify { expect(document.size).to be  == 20 }
        
        specify { expect(document[0]['linked_data_uri']).to match(country_uri_regex) }
      end

      describe 'full' do 
        let(:document) { repository.get_all({type: 'eldis', detail: 'full'}, :limit => 10) }

        specify { expect(document.class).to be == Array }
        specify { expect(document.size).to be  == 10 }
        
        specify { expect(document[0]['linked_data_uri']).to match(country_uri_regex) }
      end
    end

    context 'r4d' do
      describe 'short' do 
        let(:document) { repository.get_all({type: 'r4d', detail: 'short'}, :limit => 10) }

        specify { expect(document.class).to be == Array }
        specify { expect(document.size).to be  == 10 }
        
        specify { expect(document[0]['linked_data_uri']).to match(fao_regex) }
      end

      describe 'full' do 
        let(:document) { repository.get_all({type: 'r4d', detail: 'full'}, :limit => 10) }

        specify { expect(document.class).to be == Array }
        specify { expect(document.size).to be  == 10 }
        
        specify { expect(document[0]['linked_data_uri']).to match(fao_regex) }
      end
    end

    context 'all' do
      # use the offset parameter to test that the results contain both
      # eldis & r4d documents.
      #
      # NOTE: these specs are brittle regarding the order results are
      # returned in.
      describe 'contains eldis documents' do 
        let(:document) { repository.get_all({type: 'all', detail: 'short'}, :limit => 1, :offset => SpecValues::TOTAL_ELDIS_COUNTRIES - 1) }
      
        specify { expect(document[0]['linked_data_uri']).to match(country_uri_regex) }
      end

      describe 'contains r4d documents' do 
        let(:document) { repository.get_all({type: 'all', detail: 'full'}, :limit => 1, :offset => SpecValues::TOTAL_ELDIS_COUNTRIES) }

        specify { expect(document[0]['linked_data_uri']).to match(fao_regex) }
      end

      # NOTE as we can't easily test that all the results are
      # returned, at least test that we call both of the query clause
      # builders for eldis/r4d.
      it 'calls both the r4d and eldis query builders' do 
        repository.should_receive(:eldis_subquery)
        repository.should_receive(:r4d_subquery)
        repository.get_all({type: 'all', detail: 'full'}, :limit => 10)
      end
    end
  end

  describe '#count' do
    context 'eldis' do
      subject(:response) { repository.count('eldis', {:host => 'test.host', :limit => 10}) }
      specify { expect(response.class).to be Array }
      specify { expect(response.length).to eq(10) }
      
      context 'record' do
        subject(:record) { response.first }
        specify { expect(record.class).to be Hash }
        specify { expect(record['object_type']).to eq('country') }        
        specify { expect(record['object_name'].class).to be String }
        specify { expect(record['object_id'].class).to be String }
        specify { expect(record['count'].class).to be Fixnum }
        specify { expect(record['iso_two_letter_code']).to match(/[A-Z]{2}/) }        
        specify { expect(record['metadata_url']).to match(/http:\/\/linked-development.org\/openapi\/eldis\/get\/countries\/.*\/full/) }
      end
    end
    
    context 'r4d' do
      subject(:response) { repository.count('r4d', {:host => 'test.host', :limit => 3}) }
      specify { expect(response.class).to be Array }
      specify { expect(response.length).to eq(3) }
      
      context 'record' do
        subject(:record) { response.first }
        specify { expect(record.class).to be Hash }
        specify { expect(record['object_type']).to eq('country') }        
        specify { expect(record['object_name'].class).to be String }
        specify { expect(record['object_id'].class).to be String }
        specify { expect(record['count'].class).to be Fixnum }
        specify { expect(record['iso_two_letter_code']).to match(/[A-Z]{2}/) }        
        specify { expect(record['metadata_url']).to match(/http:\/\/linked-development.org\/openapi\/r4d\/get\/countries\/.*\/full/) }
      end
    end
    
    context 'all' do
      subject(:response) { repository.count('all', {:host => 'test.host'}) }
      specify { expect(response.class).to be Array }
      specify { expect(response.count).to be 10 }
    end
  end
end
