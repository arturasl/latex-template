all: latexpand.zip

README: latexpand
	./latexpand --help > README

.PHONY: latexpand.zip
latexpand.zip: README
	-$(RM) $@
	@echo "latexpand version $$(git rev-parse HEAD).\n\
Commited on $$(git show HEAD --pretty=format:'%cd')." > version.txt
	zip $@ README version.txt $$(git ls-files | grep -v '\.gitignore')
