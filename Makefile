COFFEEC = coffee
SASSC = sass
HAMLC = haml
.PHONY: clean all

public/%.js: source/%.coffee
	$(COFFEEC) -o public -bc $<

public/%.css: source/%.scss
	$(SASSC) -C $< > $@

public/%.html: source/%.haml
	$(HAMLC) $< > $@

SASS_SOURCES = $(wildcard source/*.scss)
COFFEE_SOURCES = $(wildcard source/*.coffee)
HAML_SOURCES = $(wildcard source/*.haml)

CSS = $(addprefix public/, $(notdir $(SASS_SOURCES:.scss=.css)))
JS = $(addprefix public/, $(notdir $(COFFEE_SOURCES:.coffee=.js)))
HTML = $(addprefix public/, $(notdir $(HAML_SOURCES:.haml=.html)))

all: $(CSS) $(JS) $(HTML)