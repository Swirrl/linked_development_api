require 'spec_helper'

describe ThemeRepository do
  
  let(:theme_uri_regex) { /http:\/\/linked-development\.org\/eldis\/themes\/C[0-9]+\// }
  let(:dbpedia_regex) { /http:\/\/dbpedia\.org\// }

  subject(:repository) { ThemeRepository.new }

  describe '#get_eldis' do
    context 'no such id' do 
      let(:document) { repository.get_eldis(type: "eldis", resource_uri: "http://linked-development.org/eldis/themes/C9999999999999/", detail: "full") }

      specify { expect(document).to be nil }
    end
    
    context 'eldis' do 
      describe "document C782" do 
        describe 'short' do 
          let(:document) { repository.get_eldis(type: "eldis", resource_uri: "http://linked-development.org/eldis/themes/C782/", detail: "short") }
          
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
        
        describe 'full' do 
          let(:document) { repository.get_eldis(type: "eldis", resource_uri: "http://linked-development.org/eldis/themes/C782/", detail: "full") }

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
                                                                             },
                                                                             {"object_name"=>"ICT for education", 
                                                                              "level"=>"1", 
                                                                              "object_id"=>"C790", 
                                                                              "linked_data_url"=>"http://linked-development.org/eldis/themes/C790/", 
                                                                              "metadata_url"=>"http://linked-development.org/openapi/eldis/get/themes/C790/full"}]
                                                                             )
          }
        end

      end
    end
    
    context 'r4d' do
      describe "document c10176" do 
        describe 'full' do 
          let(:document) { repository.get_r4d(type: "r4d", :resource_uri => "http://aims.fao.org/aos/agrovoc/c_10176", detail: "full") }

          specify { expect(document["linked_data_uri"]).to be    == "http://aims.fao.org/aos/agrovoc/c_10176" }
          specify { expect(document["object_id"]).to be == "c_10176" }
          specify { expect(document["object_type"]).to be == "theme" }
          specify { expect(document["title"]).to be == "Crop yield" }
          specify { expect(document["metadata_url"]).to be == "http://linked-development.org/openapi/r4d/get/themes/c_10176/full" }
          specify { expect(document["site"]).to be == "r4d" }
          specify { expect(document["children_url"]).to be == "http://linked-development.org/openapi/r4d/get_children/themes/c_10176/full" }
          specify { expect(document["name"]).to be == "Crop yield" }
        end
       
        describe 'short' do 
          let(:document) { repository.get_r4d(type: "r4d", resource_uri: "http://aims.fao.org/aos/agrovoc/c_10176", detail: "short") }

          specify { expect(document["linked_data_uri"]).to be == "http://aims.fao.org/aos/agrovoc/c_10176" }
          specify { expect(document["object_id"]).to be == "c_10176" }
          specify { expect(document["object_type"]).to be == "theme" }
          specify { expect(document["title"]).to be == "Crop yield" }
          specify { expect(document["metadata_url"]).to be == "http://linked-development.org/openapi/r4d/get/themes/c_10176/full" }
        end
      end
    end
  end


  describe '#get_all' do 
    # some rubbish, minimal tests... but then this stuff is awkward & brittle to test.

    context 'eldis' do
      describe 'short' do 
        let(:document) { repository.get_all({type: 'eldis', detail: 'short'}, :limit => 10) }

        specify { expect(document.class).to be == Array }
        specify { expect(document.size).to be  == 10 }
        
        specify { expect(document[0]['linked_data_uri']).to match(theme_uri_regex) }
      end

      describe 'full' do 
        let(:document) { repository.get_all({type: 'eldis', detail: 'full'}, :limit => 10) }

        specify { expect(document.class).to be == Array }
        specify { expect(document.size).to be  == 10 }
        
        specify { expect(document[0]['linked_data_uri']).to match(theme_uri_regex) }
      end
    end

    context 'r4d' do
      describe 'short' do 
        let(:document) { repository.get_all({type: 'r4d', detail: 'short'}, :limit => 10) }

        specify { expect(document.class).to be == Array }
        specify { expect(document.size).to be  == 10 }
        
        specify { expect(document[0]['linked_data_uri']).to match(dbpedia_regex) }
      end

      describe 'full' do 
        let(:document) { repository.get_all({type: 'r4d', detail: 'full'}, :limit => 10) }

        specify { expect(document.class).to be == Array }
        specify { expect(document.size).to be  == 10 }
        
        specify { expect(document[0]['linked_data_uri']).to match(dbpedia_regex) }
      end
    end

    context 'all' do
      # use the offset parameter to test that the results contain both
      # eldis & r4d documents.
      #
      # NOTE: these specs are brittle regarding the order results are
      # returned in.
      describe 'contains eldis documents' do 
        let(:document) { repository.get_all({type: 'all', detail: 'short'}, :limit => 1, :offset => SpecValues::TOTAL_ELDIS_THEMES - 1) }
      
        specify { expect(document[0]['linked_data_uri']).to match(theme_uri_regex) }
      end

      describe 'contains r4d documents' do 
        let(:document) { repository.get_all({type: 'all', detail: 'full'}, :limit => 1, :offset => SpecValues::TOTAL_ELDIS_THEMES) }

        specify { expect(document[0]['linked_data_uri']).to match(dbpedia_regex) }
      end

      # NOTE as we can't easily test that all the results are
      # returned, at least test that we call both of the query clause
      # builders for eldis/r4d.
      it 'calls both the r4d and eldis query builders' do 
        repository.should_receive(:eldis_parent_subquery)
        repository.should_receive(:r4d_parent_subquery)
        repository.get_all({type: 'all', detail: 'full'}, :limit => 10)
      end
    end
  end
end
