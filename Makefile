all: get-deps compile

get-deps:
	./rebar get-deps

compile:
	./rebar compile
	(cd apps/web/priv/static; rm -rf nitrogen; mkdir nitrogen; cp -r ../../../../deps/nitrogen_core/www/* nitrogen)

clean:
	./rebar clean
	(cd apps/web/priv/static; rm -rf nitrogen)

# web depends on myapp in web.src, but apparently this doesn't
# mean that myapp is started. Maybe this works if we do a proper release?
run:
	erl -pa apps/*/ebin ./deps/*/ebin ./deps/*/include \
	-sname nitrogen@rs \
	-setcookie ec_master \
	-eval "application:start(web)."
