require 'spec_helper'

describe ThemeRepository do

  subject(:repository) { ThemeRepository.new }

  context "eldis get themes C782 (short)" do
    let(:document) { repository.run_eldis_query(type: "eldis", resource_uri: "http://linked-development.org/eldis/themes/C782/", detail: "short") }
    
    describe "document content" do 
      specify { expect(document["linked_data_uri"]).to be    == "http://linked-development.org/eldis/themes/C782/" }
      specify { expect(document["object_id"]).to be          == "C782" }
      specify { expect(document["object_type"]).to be          == "theme" }
      specify { expect(document["title"]).to be          == "ICTs for development" }
      
      # NOTE we break the original PHP API here.  It implemented the
      # following, commented out line but we've changed it to
      # something more sane, without the slug.

      # specify { expect(document["metadata_url"]).to be          == "http://linked-development.org/openapi/eldis/get/themes/C782/full/ICTs_for_development"

      # TODO consider if this should really return a full detail URL.
      specify { expect(document["metadata_url"]).to be          == "http://linked-development.org/openapi/eldis/get/themes/C782/full" }
    end
  end
  
  context 'eldis get themes C782 (full)' do 
    let(:document) { repository.run_eldis_query(type: "eldis", resource_uri: "http://linked-development.org/eldis/themes/C782/", detail: "full") }

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
  end

  context 'r4d get c_10176 (full)' do 
    let(:document) { repository.run_r4d_query(type: "r4d", :resource_uri => "http://aims.fao.org/aos/agrovoc/c_10176", detail: "full") }

    describe "document content" do 
      specify { expect(document["linked_data_uri"]).to be    == "http://aims.fao.org/aos/agrovoc/c_10176" }
      specify { expect(document["object_id"]).to be == "c_10176" }
      specify { expect(document["object_type"]).to be == "theme" }
      specify { expect(document["title"]).to be == "Crop yield" }
      specify { expect(document["metadata_url"]).to be == "http://linked-development.org/openapi/r4d/get/themes/c_10176/full" }
      specify { expect(document["site"]).to be == "r4d" }
      specify { expect(document["children_url"]).to be == "http://linked-development.org/openapi/r4d/get_children/themes/c_10176/full" }
      
      specify { expect(document["name"]).to be == "Crop yield" }
      
    end
  end

  context 'r4d get c_10176 (short)' do 
    let(:document) { repository.run_r4d_query(type: "r4d", resource_uri: "http://aims.fao.org/aos/agrovoc/c_10176", detail: "short") }

    describe "document content" do 
      specify { expect(document["linked_data_uri"]).to be == "http://aims.fao.org/aos/agrovoc/c_10176" }
      specify { expect(document["object_id"]).to be == "c_10176" }
      specify { expect(document["object_type"]).to be == "theme" }
      specify { expect(document["title"]).to be == "Crop yield" }
      specify { expect(document["metadata_url"]).to be == "http://linked-development.org/openapi/r4d/get/themes/c_10176/full" }
    end
  end
end
