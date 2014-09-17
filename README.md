# Snapper

[![DOI](https://zenodo.org/badge/5847/jiemakel/snapper.png)](http://dx.doi.org/10.5281/zenodo.11754)

Snapper is a browser-based [Turtle](http://www.w3.org/TR/turtle/) editor. Try it at http://jiemakel.github.io/snapper/ .

Snapper supports:

* Syntax highlighting
* Autocompletion of resources based on either labels or IRI prefixes
* Autocompletion of prefixes
* Loading and storing data into an endpoint

Some of the functionalities require suitable SPARQL endpoints. Basically, the spread is as follows:

SPARQL graph store protocol endpoint:

* loading/replacing by graph, adding triples

SPARQL update endpoint:

* deleting/replacing individual resources

SPARQL query endpoint:

* label autocompletion & label display
* listing graphs in the graph store
* single resource loading (but Snapper can also load resources with simple GETs)

Being a completely client-side application, Snapper also requires all these endpoints to set appropriate CORS-headers. 

If your endpoint does not set appropriate CORS-headers, you can use it through a CORS-proxy, like http://ldf.fi/corsproxy (for http://ldf.fi/corsproxy, append your URL without http://, e.g. http://ldf.fi/corsproxy/dbpedia.org/sparql). 

Another option is to deploy the Snapper application locally in your own domain.

## Licensing

Snapper is licensed under the terms of the MIT license.

## Installing

Should you wish to run your own instance of Snapper, you need to:

1) check out the project from GitHub and 2) install the required dependencies by running:

	npm install
	bower install
	
After this, you can run a local instance of the tool by entering:

	gulp serve
	
If you want to create the distribution version of the project, you need to run:

	gulp dist
	
This will create a dist folder under the project, which you can then deploy to any web server of your choice.
