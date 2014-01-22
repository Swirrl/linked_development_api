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

## Differences from the PHP implementation

This implementation fixes a number of issues which were present in the
original PHP code base.  These changes may break backwards
compatability with existing client implementations, so they have been
documented here.

### General Changes (Across all applicable routes)

- TODO

### Themes

- The original API included a typing mistake in the JSON object
  returned by themes, where it used the key "linked\_data\_url" where
  as the rest of the API uses the key "linked\_data\_uri".  This has
  been corrected to use the key "linked\_data\_uri".

### Countries

### Research Outputs

