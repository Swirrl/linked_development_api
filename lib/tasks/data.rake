namespace :data do
  namespace :load do
    def test_graph_uri(database, graph)
      "http://localhost:3030/#{database}/data?graph=#{graph}"
    end

    def put_file_to_db_graph(filename, database, graph)
      cmd = "curl -X PUT --data-binary @#{filename} -H 'Content-Type: application/n-triples' " <<
            "'#{test_graph_uri(database, graph)}'"
      puts cmd
      system cmd
    end

    desc "Load the sample data into a local development database"
    task :development do
      put_file_to_db_graph(
        "data/eldis.nt", "linkeddev-dev", "http://linked-development.org/graph/eldis"
      )
      put_file_to_db_graph(
        "data/r4d.nt", "linkeddev-dev", "http://linked-development.org/graph/r4d"
      )
    end

    desc "Load the sample data into a local test database"
    task :test do
      put_file_to_db_graph(
        "data/eldis.nt", "linkeddev-test", "http://linked-development.org/graph/eldis"
      )
      put_file_to_db_graph(
        "data/r4d.nt", "linkeddev-test", "http://linked-development.org/graph/r4d"
      )
    end
  end
end
