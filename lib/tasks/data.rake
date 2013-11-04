namespace :data do
  namespace :load do
    def test_graph_uri(database, graph)
      "http://localhost:3030/#{database}/data?graph=#{graph}"
    end

    def put_file_to_db_graph(filename, database, graph)
      system(
        "curl -X PUT --data-binary @#{filename} -H 'Content-Type: text/plain' " <<
        "'#{test_graph_uri(database, graph)}'"
      )
    end

    desc "Load the sample data into a local development database"
    task :development do
      put_file_to_db_graph(
        "data/eldis.nt", "linkeddev-dev", "http://linked-development.org/eldis/"
      )
      put_file_to_db_graph(
        "data/r4d.nt", "linkeddev-dev", "http://linked-development.org/r4d/"
      )
    end

    desc "Load the sample data into a local test database"
    task :test do
      put_file_to_db_graph(
        "data/eldis.nt", "linkeddev-test", "http://linked-development.org/eldis/"
      )
      put_file_to_db_graph(
        "data/r4d.nt", "linkeddev-test", "http://linked-development.org/r4d/"
      )
    end
  end
end