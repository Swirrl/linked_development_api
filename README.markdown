# Linked Development

## Importing initial data

Initial data for the two datasets (ELDIS and Research for Development is stored in the `data` folder). For now, you can import it into Fuseki with the following command:

    rake data:load:development

Note that the initial tests are written against existing sample API output, so you need to load the test data for this too:

    rake data:load:test