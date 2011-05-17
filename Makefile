all: get-deps compile

get-deps:
	./rebar get-deps

rel: all
	./rebar generate
	chmod u+x rel/ec_web/bin/ec_web

compile:
	./rebar compile
	(cd apps/view/priv/static; rm -rf nitrogen; mkdir nitrogen; cp -r ../../../../deps/nitrogen_core/www/* nitrogen;cp -r ../*.gif nitrogen/.)

clean:
	./rebar clean
