all: get-deps compile

get-deps:
	rebar get-deps

rel: all
	rebar generate
	chmod u+x rel/ec_web/bin/ec_web

compile:
	rebar compile
	(rm -rf priv/static/nitrogen; mkdir priv/static/nitrogen; \
	cp -r deps/nitrogen_core/www/* priv/static/nitrogen/; \
	cp -r deps/nitrogen_elements/www/* priv/static/ ; \
	cp -r priv/*.gif priv/static/nitrogen/. ;)
clean:
	rebar clean
