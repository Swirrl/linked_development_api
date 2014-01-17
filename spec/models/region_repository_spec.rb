require 'spec_helper'

describe RegionRepository do 
  let(:region_uri_regex) { /http:\/\/linked-development\.org\/eldis\/regions\/[A-Z][0-9]+\// }
  let(:dbpedia_regex) { /http:\/\/dbpedia\.org\// }

  subject(:repository) { RegionRepository.new }

  describe '#get_eldis' do
    context 'no such id' do 
      let(:document) { repository.get_eldis(type: "eldis", resource_uri: "http://linked-development.org/eldis/geography/C9999999999999999999/", detail: "full") }

      specify { expect(document).to be nil }
    end
    
    context 'eldis' do 
      describe 'region C21' do 
        describe 'short' do 
          let(:document) { repository.get_eldis(type: "eldis", resource_uri: "http://linked-development.org/eldis/geography/C21/", detail: "short") }
          
          specify { expect(document["linked_data_uri"]).to be    == "http://linked-development.org/eldis/geography/C21/" }
          specify { expect(document["object_id"]).to be          == "C21" }
          specify { expect(document["object_type"]).to be          == "region" }
          specify { expect(document["title"]).to be          == "Africa South of Sahara" }

          specify { expect(document["metadata_url"]).to be          == "http://linked-development.org/openapi/eldis/get/regions/C21/full" }
        end
        
        describe 'full' do 
          let(:document) { repository.get_eldis(type: "eldis", resource_uri: "http://linked-development.org/eldis/geography/C21/", detail: "full") }

          specify { expect(document["linked_data_uri"]).to be    == "http://linked-development.org/eldis/geography/C21/" }
          specify { expect(document["object_id"]).to be          == "C21" }
          specify { expect(document["object_type"]).to be          == "region" }
          specify { expect(document["title"]).to be          == "Africa South of Sahara" }

          specify { expect(document["metadata_url"]).to be          == "http://linked-development.org/openapi/eldis/get/regions/C21/full" }
        end

      end
    end
    
    context 'r4d' do
      describe "region 061" do 
        let(:document) { repository.get_r4d(type: "r4d", id: "061", detail: "full") }

        describe 'full' do 
          specify { expect(document["linked_data_uri"]).to be    == "http://www.fao.org/countryprofiles/geoinfo/geopolitical/resource/Polynesia" }
          specify { expect(document["object_id"]).to be          == "061" }
          specify { expect(document["object_type"]).to be          == "region" }
          specify { expect(document["title"]).to be          == "Polynesia" }

          specify { expect(document["metadata_url"]).to be          == "http://linked-development.org/openapi/r4d/get/regions/061/full" }
        end
       
        describe 'short' do 

        end
      end
    end
  end
end

