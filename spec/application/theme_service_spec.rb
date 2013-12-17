require 'spec_helper'

describe ThemeService do
  let(:service) { ThemeService.build }

  def sample_file(filename)
    File.read(File.dirname(__FILE__) + "/samples/#{filename}")
  end

  context "parameter validation" do 
    describe 'raises error' do 
      it 'InvalidDocumentType when type is not one of eldis, r4d, or all' do 
        expect {service.get type: 'foo', id: 'C782', detail: 'short'}.to raise_error InvalidDocumentType
      end
    end
  end

  context "themes document C782 (short)" do
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
      specify { expect(document["metadata_url"]).to be          == "http://linked-development.org/openapi/eldis/get/themes/C782" }
    end

    describe "metadata" do
        pending
    end

    describe "JSON output" do
      let(:json_output) { response.to_json }

      example "complete document" do
        expect(
          JSON.parse(json_output)
        ).to be == JSON.parse(sample_file("eldis_theme_C6782_short.json")) 
      end
    end
  end
end
