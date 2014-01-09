
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
  shared_examples 'example documents' do |graph_name, method_name, object_type, opts_or_id, test_opts=nil|

    let(:obj_id)      { opts_or_id.class == String ? opts_or_id : nil }  # allowed to be nil in the case of e.g. get_all
    let(:opts_hash)   { opts_or_id } # allowed to be nil in the case of e.g. get_all
    
    ['short', 'full'].each do |detail| 
      context detail do
        let(:json_output) { 
          if method_name == :get_all
            service.send(method_name, {type: graph_name.to_s, detail: detail}, opts_hash) 
          else # get, count etc...
            service.send(method_name, {type: graph_name.to_s, id: obj_id, detail: detail}) 
          end
        }
        
        example "matches example document #{generate_filename(graph_name, method_name, object_type, opts_or_id, detail, test_opts)}" do
          filename = generate_filename(graph_name, method_name, object_type, opts_or_id, detail, test_opts)
          expect(sort_json(json_output)).to be == sort_json(sample_json(filename))
        end
      end
    end
  end

  def generate_filename graph_name, method_name, object_type, opts_or_id, detail, test_opts
    if test_opts && test_opts[:filename]
      "#{test_opts[:filename]}_#{detail}.json" # for where we have an id
    else
      obj_name = (opts_or_id.class == String) ? "#{opts_or_id}_" : ''
      "#{graph_name}_#{method_name}_#{object_type}_#{obj_name}#{detail}.json"
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
