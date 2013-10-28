# Linked Development

## Importing initial data

Initial data for the two datasets (ELDIS and Research for Development is stored in the `data` folder). For now, you can import it into Fuseki with the following commands:

    curl -X PUT --data-binary @data/eldis.nt -H 'Content-Type: application/n-triples' 'http://localhost:3030/linkeddev-dev/data?graph=http://linked-development.org/eldis/'

    curl -X PUT --data-binary @data/r4d.nt -H 'Content-Type: application/n-triples' 'http://localhost:3030/linkeddev-dev/data?graph=http://linked-development.org/r4d/'