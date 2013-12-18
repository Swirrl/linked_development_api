# Linked Development

## Importing initial data

Initial data for the two datasets (ELDIS and Research for Development is stored in the `data` folder). For now, you can import it into Fuseki with the following command:

    rake data:load:development

Note that the initial tests are written against existing sample API output, so you need to load the test data for this too:

    rake data:load:test

These commands import the data into a PMD compatible graph with the following URI's: 

- http://linked-development.org/graph/eldis
- http://linked-development.org/graph/r4d

You may need to increase Fuseki's heap size to import the data properly by modifying the fuseki-server shell script to use a 4gb heap size:

JVM_ARGS=${JVM_ARGS:--Xmx4096M}
