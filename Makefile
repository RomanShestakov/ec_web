REBAR=rebar

all: get-deps compile

get-deps:
	$(REBAR) get-deps

rel: all
	$(REBAR) generate
	#chmod u+x rel/ec_web/bin/ec_web

compile:
	$(REBAR) compile
	#(cd priv/static; rm -rf nitrogen; mkdir nitrogen; cp -r ../../deps/nitrogen_core/www/* nitrogen)

clean:
	$(REBAR) clean

