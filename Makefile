COFFEEC = coffee
SASSC = sass
HAMLC = haml
.PHONY: clean all

public/%.js: source/%.js
	cp $< public/

public/%.css: source/%.css
	cp $< public/

public/%.js: source/%.coffee
	$(COFFEEC) -o public -bc $<

public/%.css: source/%.scss
	$(SASSC) -C $< > $@

public/%.html: source/%.haml
	$(HAMLC) $< > $@

SASS_SOURCES = $(wildcard source/*.scss)
COFFEE_SOURCES = $(wildcard source/*.coffee)
JS_SOURCES = $(wildcard source/*.js)
CSS_SOURCES = $(wildcard source/*.css)
HAML_SOURCES = $(wildcard source/*.haml)

CSS = $(addprefix public/, $(notdir $(SASS_SOURCES:.scss=.css)))
JS = $(addprefix public/, $(notdir $(COFFEE_SOURCES:.coffee=.js)))
RAWJS = $(addprefix public/, $(notdir $(JS_SOURCES)))
RAWCSS = $(addprefix public/, $(notdir $(CSS_SOURCES)))
HTML = $(addprefix public/, $(notdir $(HAML_SOURCES:.haml=.html)))

all: $(CSS) $(JS) $(RAWJS) $(RAWCSS) $(HTML)

clean:
	rm -rf public/*