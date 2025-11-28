.PHONY: build serve clean update deploy update-deploy stash

plantuml.jar:
	wget -O plantuml.jar http://sourceforge.net/projects/plantuml/files/plantuml.jar/download

%.png: %.uml plantuml.jar
	java -jar plantuml.jar $<

clean:
	rm -rf env site/specs mkdocsrc

env:
	python -m venv env && . env/bin/activate; pip install mkdocs mkdocs-material mdx-spanner mkdocs-mermaid2-plugin mkdocs-git-authors-plugin mkdocs-git-revision-date-localized-plugin

mkdocsrc:
	mkdir $@ &&\
	cd $@ &&\
	git clone https://github.com/annotation/stam-tools tools &&\
	ln -s ../extensions &&\
	ln -s ../examples &&\
	ln -s ../README.md &&\
	ln -s ../model.png &&\
	ln -s ../coremodel.png &&\
	ln -s ../coremodel_schema.png &&\
	ln -s ../logo.png &&\
	cd -

specs: env mkdocsrc
	. env/bin/activate; mkdocs build --site-dir site/specs

serve: env mkdocsrc
	. env/bin/activate; mkdocs serve

update:
	git pull
