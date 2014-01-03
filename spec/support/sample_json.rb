module SampleJson

  # Build a test for both short/full documents based on the inferred
  # filename from the passed parameter array.  If a final arg is
  # supplied it is used as an override for the inferred filename.
  # NOTE there appears to be a bug with rspec splatting the arguments
  # that are passed into this block, so we need to double wrap our
  # arrays when using this rspec macro.
  #
  # params_array follows the structure of the URI e.g.
  #
  # [:graph, :function, :object, :id?] 
  #
  # tests for both short & full are generated for each example.
  shared_examples 'example documents' do |params_array, filename_override=nil|
    let(:graph_name)  { params_array[0].to_s }
    let(:method_name) { params_array[1] }
    let(:obj_id)      { params_array[3] } # allowed to be nil in the case of e.g. get_all
        
    ['short', 'full'].each do |detail| 
      context detail do
        let(:filename) do 
          filename_override ? "#{filename_override}_#{detail}.json" 
                            : "#{params_array.join('_')}_#{detail}.json"
        end
        let(:response) { service.send(method_name, {type: graph_name, id: obj_id , detail: detail}) }
        let(:json_output) { response }
        
        example "matches example document #{filename_override || params_array.join('_')}_#{detail}.json" do
          expect(sort_json(json_output)).to be == sort_json(sample_json(filename))
        end
      end
    end
  end
  
  def sample_json(filename)
    JSON.parse(File.read(File.join(File.dirname(__FILE__), '..' , 'application', 'samples', filename)))
  end

  # SORT JSON objects to help aid comparisons in tests.
  def sort_json unsorted_hash
    sorted_hash = Hash.new

    unsorted_hash.keys.sort.reverse.each do |k| 
      v = unsorted_hash[k]
      v = sort_json(v) if v.class == Hash
      
      if v.class == Array
        v.each_with_index do |o, i| 
          if o.class == Hash
            v[i] = sort_json o
          end
        end
        
        # crude assumption about sorting arrays if an object_id is present in a nested object
        v = v.sort { |o1,o2| o1['object_id'] <=> o2['object_id'] } if v[0].present? && v[0]['object_id'].present?
      end
      
      sorted_hash[k] = v
    end
    
    sorted_hash
  end
end
