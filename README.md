Snapper
====

Snapper is a browser-based [Turtle](http://www.w3.org/TR/turtle/) editor. Try it at http://jiemakel.github.io/snapper/ .

It supports:
* Syntax highlighting
* Autocompletion of resources
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

Being a completely client-side application, Snapper also requires all these endpoints to set appropriate CORS-headers. If your endpoint does not, you can use it through a CORS-proxy, like http://ldf.fi/corsproxy (for http://ldf.fi/corsproxy, append your URL without http://, e.g. http://ldf.fi/corsproxy/dbpedia.org/sparql)
