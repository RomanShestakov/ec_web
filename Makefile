all: get-deps compile

get-deps:
	./rebar get-deps

rel: all
	./rebar generate
	chmod u+x rel/ec_web/bin/ec_web

compile:
	./rebar compile
	(cd priv/static; rm -rf nitrogen; mkdir nitrogen; cp -r ../../deps/nitrogen_core/www/* nitrogen)

clean:
	./rebar clean


# web depends on myapp in web.src, but apparently this doesn't
# mean that myapp is started. Maybe this works if we do a proper release?
run:
	erl -pa ebin ./deps/*/ebin ./deps/*/include \
	-sname nitrogen \
	-setcookie ec_master \
	-eval "application:start(web)."
