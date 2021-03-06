require 'exceptions'

class CountryService < AbstractService

  class << self
    # Convenience factory method to construct a new DocumentService
    # with the usual dependencies
    def build
      new(repository: CountryRepository.new)
    end
  end

  def get_all details, opts
    results = do_get_all details, opts

    base_url = Rails.application.routes.url_helpers.get_all_countries_url(@type, {:host => opts[:host], :format => @format, :detail => @detail})

    wrap_results(results, base_url)
  end

  def count details, opts
    set_instance_vars details, opts
    base_url = Rails.application.routes.url_helpers.count_countries_url(@type, {:host => opts[:host], :format => @format})
    results = super(details, opts)
    wrap_count_results results, base_url
  end

  private

  def self.is_eldis_id? res_id
    res_id =~ /^A\d{1,}$/
  end

  def convert_id_to_uri res_id
    if CountryService.is_eldis_id? res_id
      "http://linked-development.org/eldis/geography/#{res_id}/"
    else # resolve to an fao ontology URI
      "http://www.fao.org/countryprofiles/geoinfo/geopolitical/resource/#{res_id}"
    end
  end
end
