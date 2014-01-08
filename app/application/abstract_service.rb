class AbstractService
  protected

  def set_instance_vars details
    @type = details.fetch(:type)
    @detail = details[:detail]
    @resource_id = details[:id] # allow nil
  end

  def parse_limit i
    i == nil ? 10 : Integer(i)
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

  def wrap_results results
    # TODO generate summary
    {
      'results' => results,
        "metadata" => {
                       "num_results"   => @repository.total_results_of_last_query,
                       "start_offset"  => 0
                      }
    }
  end

  def validate
    raise LinkedDevelopmentError, 'Detail must be either full, short or unspecified (in which case it defaults to short).' unless detail_valid?
    raise InvalidDocumentType unless graph_valid?
  end

end
