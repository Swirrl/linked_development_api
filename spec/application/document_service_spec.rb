require 'spec_helper'

describe DocumentService do
  let(:service) { DocumentService.build }

  def sample_file(filename)
    File.read(File.dirname(__FILE__) + "/samples/#{filename}")
  end

  context "ELDIS document A64559" do
    let(:document) { service.get(type: "eldis", id: "A64559", detail: "full") }

    describe "document content" do
      specify { expect(document["object_type"]).to be       == "Document" }
      specify { expect(document["object_id"]).to be         == "A64559" }
      specify { expect(document["title"]).to be             == "Using ICT to Develop Literacy" }
      specify { expect(document["name"]).to be              == "Using ICT to Develop Literacy" }
      specify { expect(document["publication_date"]).to be  == "2006-01-01 00:00:00" }
      specify { expect(document["publication_year"]).to be  == "2006" }
      specify { expect(document["publisher"]).to be         == "UNESCO Bangkok" }
      specify { expect(document["site"]).to be              == "eldis" }
      specify { expect(document["website_url"]).to be_a(String) } # URIs don't convert to JSON nicely
      specify { expect(document["website_url"]).to be       == "http:\/\/www.eldis.org\/go\/display?type=Document&id=64559" }
      specify {
        expect(document["category_theme_array"]).to match_array(
          [
            {
                 "archived"     => "false",
                 "level"        => "unknown",
                 # We need route generation for this:
                 # "metadata_url" => "http://linked-development.org/openapi/eldis/get/themes/C790",
                 "object_id"    => "C790",
                 "object_name"  => "ICT for education",
                 "object_type"  => "theme"
            },
            {
                "archived"      => "false",
                "level"         => "unknown",
                # We need route generation for this:
                # "metadata_url"  => "http://linked-development.org/openapi/eldis/get/themes/C782",
                "object_id"     => "C782",
                "object_name"   => "ICTs for development",
                "object_type"   => "theme"
            }
          ]
        )
      }
      specify { expect(document["category_theme_ids"]).to match_array(%w[C790 C782]) }
      specify {
        expect(document["country_focus_array"]["Country"]).to match_array(
          [
            {
                "alternative_name"    => "Thailand",
                "iso_two_letter_code" => "TH",
                # We need route generation for this:
                # "metadata_url"        => "http://linked-development.org/openapi/eldis/get/countries/TH/full",
                "object_id"           => "TH",
                "object_name"         => "Thailand",
                "object_type"         => "Country"
            }
          ]
        )
      }
      specify { expect(document["country_focus"]).to be == ["Thailand"] }
      specify { expect(document["country_focus_ids"]).to be == ["TH"] }
    end

    describe "JSON output" do
      let(:json_output) { document.to_json }

      example "complete document" do
        pending "to do at the end"
        expect(
          JSON.parse(json_output)
        ).to be == JSON.parse(sample_file("eldis_document_A64559.json"))
      end
    end
  end

  context "Multiple creators (ELDIS document A64840)" do
    let(:document) { service.get(type: "eldis", id: "A64840", detail: "full") }
    let(:json_output) { document.to_json }
    let(:parsed_json_output) { JSON.parse(json_output) }

    specify {
      expect(parsed_json_output["author"]).to match_array(
        ["R. Wickramasinghe", "J. Chandrasiri", "C. Anuranga"]
      )
    }
  end

  context "No publisher (ELDIS document A64882)" do
    let(:document) { service.get(type: "eldis", id: "A64882", detail: "full") }
    let(:json_output) { document.to_json }
    let(:parsed_json_output) { JSON.parse(json_output) }

    describe "multiple creators" do
      # Current behaviour, may or may not be correct
      specify {
        expect(parsed_json_output).to have_key("publisher")
      }

      specify {
        expect(parsed_json_output["publisher"]).to be_nil
      }
    end
  end

  context "Region coverage (ELDIS document A64882)" do
  	let(:document) { service.get(type: "eldis", id: "A64882", detail: "full") }
    let(:json_output) { document.to_json }
    let(:parsed_json_output) { JSON.parse(json_output) }

    describe "region" do
      specify {
        expect(parsed_json_output["category_region_array"]).to be == {
          "Region" => [
            {
              "archived"      => "false",
              "deleted"       => "0",
              # We need route generation for this:
              # "metadata_url"  => "http://linked-development.org/openapi/eldis/get/regions/C30/full",
              "object_id"     => "C30",
              "object_name"   => "South Asia",
              "object_type"   => "region"
            }
          ]
        }
      }

      specify {
        expect(parsed_json_output["category_region_path"]).to be == ["South Asia"]
      }

      specify {
        expect(parsed_json_output["category_region_ids"]).to be == ["C30"]
      }

      specify {
      	expect(parsed_json_output["category_region_objects"]).to be == ["C30|region|South Asia"]
      }
    end
  end

  # I looked into the data and it appears this is only ever used for R4D,
  #  documents not ELDIS ones. I don't know if this is by design or coincidence.
  context "Region (not country) with a UN code (not identifier) (R4D document 187524)" do
    let(:document) { service.get(type: "r4d", id: "187524", detail: "full") }
    let(:json_output) { document.to_json }
    let(:parsed_json_output) { JSON.parse(json_output) }

    specify {
      expect(parsed_json_output["category_region_ids"]).to be == ["UN002"]
    }
  end

  # I looked into the data an it appears *all* of the ELDIS documents have
  # website URLs, and none of the R4D ones do. We may or may not want to be
  # more explicit about this in future.
  context "No website URL (R4D document 187524)" do
    let(:document) { service.get(type: "r4d", id: "173629", detail: "full") }
    let(:json_output) { document.to_json }
    let(:parsed_json_output) { JSON.parse(json_output) }

    # Current behaviour, may or may not be correct
    specify {
      expect(parsed_json_output).to have_key("website_url")
    }

    specify {
      expect(parsed_json_output["website_url"]).to be_nil
    }
  end

  context "Theme without an identifier (R4D document 56570)" do
    let(:document) { service.get(type: "r4d", id: "56570", detail: "full") }
    let(:json_output) { document.to_json }
    let(:parsed_json_output) { JSON.parse(json_output) }

    describe "themes" do
      let(:example_theme) {
        parsed_json_output["category_theme_array"].detect { |theme|
          theme["object_name"] == "Crops"
        }
      }

      it "uses the end of the theme URI" do
        expect(example_theme["object_id"]).to be == "c_1972"
      end
    end
  end
end