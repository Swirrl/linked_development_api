require 'spec_helper'

describe MetadataURLGenerator do
  subject(:generator) {
    MetadataURLGenerator.new("http://example.com")
  }

  example "documents" do
    expect(
      generator.document_url("eldis", "A64559")
    ).to be == "http://example.com/openapi/eldis/get/documents/A64559/full"
  end

  example "themes" do
    expect(
      generator.theme_url("eldis", "C782")
    ).to be == "http://example.com/openapi/eldis/get/themes/C782"
  end

  example "countries" do
    expect(
      generator.country_url("r4d", "TH")
    ).to be == "http://example.com/openapi/r4d/get/countries/TH/full"
  end

  example "regions" do
    expect(
      generator.region_url("eldis", "C30")
    ).to be == "http://example.com/openapi/eldis/get/regions/C30/full"
  end
end