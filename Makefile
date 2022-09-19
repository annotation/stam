plantuml.jar:
	wget -O plantuml.jar http://sourceforge.net/projects/plantuml/files/plantuml.jar/download

%.png: %.uml plantuml.jar
	java -jar plantuml.jar $<

