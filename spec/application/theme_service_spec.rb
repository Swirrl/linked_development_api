require 'spec_helper'

describe ThemeService do
  let(:service) { ThemeService.build }

  context "parameter validation" do 
    describe 'raises error' do 
      it 'InvalidDocumentType when type is not one of eldis, r4d, or all' do 
        expect {service.get type: 'foo', id: 'C782', detail: 'short'}.to raise_error InvalidDocumentType
      end
    end
    
    describe 'when type is all' do 
      let(:theme_repository) { double('theme-repository') }
      
      before :each do 
        theme_repository.stub(:run_eldis_query)
      end

      let(:service) { ThemeService.new :theme_repository => theme_repository }

      it 'determines an r4d get if the :id begins with c_' do
        theme_repository.should_receive(:run_r4d_query)
        service.get type: 'all', id: 'c_10176', detail: 'short'
      end

      it 'determines an eldis get if the :id begins with C' do 
        theme_repository.should_receive(:run_eldis_query)
        service.get type: 'all', id: 'C785', detail: 'short'
      end
      
      it 'raises a LinkedDevelopmentError if it doesnt recognise the format of the :id' do 
        expect {service.get type: 'all', id: 'invalid_id_format_1', detail: 'short'}.to raise_error LinkedDevelopmentError
      end
    end
    
  end

  context "eldis get themes C782 (short)" do
    let(:response) { service.get(type: "eldis", id: "C782", detail: "short") }
    let(:document) { response["results"].first }
    
    describe "document content" do 
      specify { expect(document["linked_data_uri"]).to be    == "http://linked-development.org/eldis/themes/C782/" }
      specify { expect(document["object_id"]).to be          == "C782" }
      specify { expect(document["object_type"]).to be          == "theme" }
      specify { expect(document["title"]).to be          == "ICTs for development" }
      
      # Break the original here.  PHP API implements the following,
      # but we've changed it to something more sane.

      # specify { expect(document["metadata_url"]).to be          == "http://linked-development.org/openapi/eldis/get/themes/C782/full/ICTs_for_development"

      # TODO consider if this should really return a full detail URL.
      specify { expect(document["metadata_url"]).to be          == "http://linked-development.org/openapi/eldis/get/themes/C782/full" }
    end

    describe "JSON output" do
      let(:json_output) { response.to_json }
      
      example "complete document" do
        expect(JSON.parse(json_output)).to be == sample_json("eldis_theme_C782_short.json")
      end
    end
  end
  
  context 'eldis get themes C782 (full)' do 
    let(:response) { service.get(type: "eldis", id: "C782", detail: "full") }
    let(:document) { response["results"].first }

    describe "document content" do 
      specify { expect(document["linked_data_uri"]).to be    == "http://linked-development.org/eldis/themes/C782/" }
      specify { expect(document["object_id"]).to be          == "C782" }
      specify { expect(document["object_type"]).to be          == "theme" }
      specify { expect(document["title"]).to be          == "ICTs for development" }
      specify { expect(document["site"]).to be          == "eldis" }
      
      # NOTE: The PHP API is inconsistent here... name appears to be
      # object_name in children.  Currently we replicate their
      # behaviour.
      specify { expect(document["name"]).to be          == "ICTs for development" }

      specify { expect(document["children_url"]).to be          == "http://linked-development.org/openapi/eldis/get_children/themes/C782/full" }

      # Break the original here.  PHP API implements the following,
      # but we've changed it to something more sane.

      # specify { expect(document["metadata_url"]).to be          == "http://linked-development.org/openapi/eldis/get/themes/C782/full/ICTs_for_development"

      # TODO consider if this should really return a full detail URL.
      specify { expect(document["metadata_url"]).to be          == "http://linked-development.org/openapi/eldis/get/themes/C782/full" }

      specify {
        expect(document["children_object_array"]["child"]).to match_array(
          [
           {"object_name"=>"ICTs and governance",
            "level"=>"1",
            "object_id"=>"C787",
            "linked_data_url"=>"http://linked-development.org/eldis/themes/C787/",
            "metadata_url"=>"http://linked-development.org/openapi/eldis/get/themes/C787/full"
           },
           
           {"object_name"=>"ICTs and agriculture",
            "level"=>"1",
            "object_id"=>"C1849",
            "linked_data_url"=>"http://linked-development.org/eldis/themes/C1849/",
            "metadata_url"=>"http://linked-development.org/openapi/eldis/get/themes/C1849/full"
           },
           
           {"object_name"=>"Government and donor policy",
            "level"=>"1",
            "object_id"=>"C789",
            "linked_data_url"=>"http://linked-development.org/eldis/themes/C789/",
            "metadata_url"=>"http://linked-development.org/openapi/eldis/get/themes/C789/full"
           },
           
           {"object_name"=>"Mobile and telecentre innovation",
            "level"=>"1",
            "object_id"=>"C833",
            "linked_data_url"=>"http://linked-development.org/eldis/themes/C833/",
            "metadata_url"=>"http://linked-development.org/openapi/eldis/get/themes/C833/full"
           },
           
           {"object_name"=>"ICT gender",
            "level"=>"1",
            "object_id"=>"C826",
            "linked_data_url"=>"http://linked-development.org/eldis/themes/C826/",
            "metadata_url"=>"http://linked-development.org/openapi/eldis/get/themes/C826/full"
           },
           
           {"object_name"=>"Manuals and toolkits",
            "level"=>"1",
            "object_id"=>"C1812",
            "linked_data_url"=>"http://linked-development.org/eldis/themes/C1812/",
            "metadata_url"=>"http://linked-development.org/openapi/eldis/get/themes/C1812/full"
           },
           
           {"object_name"=>"ICTs and livelihoods",
            "level"=>"1",
            "object_id"=>"C1850",
            "linked_data_url"=>"http://linked-development.org/eldis/themes/C1850/",
            "metadata_url"=>"http://linked-development.org/openapi/eldis/get/themes/C1850/full"
           },
           
           {"object_name"=>"Open development",
            "level"=>"1",
            "object_id"=>"C832",
            "linked_data_url"=>"http://linked-development.org/eldis/themes/C832/",
            "metadata_url"=>"http://linked-development.org/openapi/eldis/get/themes/C832/full"
           },
           
           {"object_name"=>"ICTs and health",
            "level"=>"1",
            "object_id"=>"C1813",
            "linked_data_url"=>"http://linked-development.org/eldis/themes/C1813/",
            "metadata_url"=>"http://linked-development.org/openapi/eldis/get/themes/C1813/full"
           }
          ]
        )
      }
    end

    describe "JSON output" do
      let(:json_output) { response.to_json }
      
      example "complete document" do
        expect(JSON.parse(json_output)).to be == sample_json("eldis_theme_C782.json")
      end
    end
  end

  context 'r4d get c_10176 (full)' do 
    let(:response) { service.get(type: "eldis", id: "C782", detail: "full") }

    describe "document content" do 
      
    end

    describe "JSON output" do
      let(:json_output) { response.to_json }
      
      example "complete document" do
        expect(JSON.parse(json_output)).to be == sample_json("eldis_theme_C782.json")
      end
    end
  end

  context 'r4d get c_10176 (short)' do 
    let(:response) { service.get(type: "eldis", id: "C782", detail: "full") }

    describe "document content" do 
    end
    
    describe "JSON output" do
      let(:json_output) { response.to_json }
      
      example "complete document" do
        expect(JSON.parse(json_output)).to be == sample_json("eldis_theme_C782.json")
      end
    end
  end
end
  

