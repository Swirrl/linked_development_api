namespace :data do

  namespace :load do
    def get_graph_uri(graph)

      "#{Tripod.data_endpoint.gsub('sparql', 'data')}?graph=#{graph}"
    end

    def put_file_to_db_graph(filename, graph)
      cmd = "curl -X PUT --data-binary @#{filename} -H 'Content-Type: application/n-triples' " <<
            "'#{get_graph_uri(graph)}'"
      puts cmd
      system cmd
    end

    desc "Load the sample data into a local development database"
    task sample_data: :environment do
      put_file_to_db_graph(
        "#{File.join(Rails.root, 'data/eldis.nt')}", "http://linked-development.org/graph/eldis"
      )
      put_file_to_db_graph(
        "#{File.join(Rails.root, 'data/r4d.nt')}", "http://linked-development.org/graph/r4d"
      )
    end
  end
end
