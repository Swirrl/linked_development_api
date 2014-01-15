class AbstractService

  def initialize(dependencies = { })
    @repository = dependencies.fetch(:repository)
  end

  def get details
    set_instance_vars details
    validate 
    merge_uri_with! details
    
    result = @repository.get_one(details)

    wrap_result(result)
  end

  def do_get_all details, opts
    set_instance_vars details, opts
    validate 
    @repository.get_all details, opts
  end

  protected

  def set_instance_vars details, opts=nil
    @type = details.fetch(:type)
    @detail = details[:detail]
    @resource_id = details[:id] # allow nil

    if opts.present?
      @offset = (opts[:offset] || 0).to_i
      @limit = (opts[:limit] || 10).to_i
    end
    
    Rails.logger.info "set offset to #{@offset} #{details.inspect}"
  end

  def graph_valid? 
    %w[eldis r4d all].include?(@type)
  end

  def detail_valid?
    ['full', 'short', nil].include? @detail
  end

  def wrap_result result
    raise DocumentNotFound, "No resource found with id #{@resource_id} not found" if result.nil?
    {
      "results" => [result]
    }
  end

  def merge_uri_with! details 
    resource_uri = convert_id_to_uri(@resource_id)
    details.merge! :resource_uri => resource_uri
  end
  
  def convert_id_to_uri id
    raise StandardError, 'Override #convert_id_to_uri in subclass to use #merge_uri_with'
  end

  def wrap_results results, base_url
    {
      'results' => results,
      'metadata' => metadata(base_url)
    }
  end

  def metadata base_url
    number_of_matched_results = @repository.total_results_of_last_query

    offset = @offset.present? ? Integer(@offset) : 0
    limit = @limit.present? ? Integer(@limit) : 10

    params = {:num_results => limit}

    ret = {
     "num_results"   => number_of_matched_results,
     "start_offset"  => offset
    }

    next_offset = offset + limit
    prev_offset = offset - limit

    if next_offset < number_of_matched_results
      next_params = params.merge(:start_offset => next_offset).to_query
      ret['next_page'] = "#{base_url}?#{next_params}"
    end

    if prev_offset > 0
      prev_params = params.merge(:start_offset => prev_offset).to_query
      ret['prev_page'] = "#{base_url}?#{prev_params}"
    end
    
    ret
  end

  def validate
    raise LinkedDevelopmentError, 'Detail must be either full, short or unspecified (in which case it defaults to short).' unless detail_valid?
    raise InvalidDocumentType, "Graph #{@type} is not valid." unless graph_valid?
  end

end
