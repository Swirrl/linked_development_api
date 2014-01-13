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

    #base_url = Rails.application.routes.url_helpers.get_all_country_url(@type, {:host => opts[:host], :format => :json, :detail => @detail})

    wrap_results(results, base_url)
  end


end
