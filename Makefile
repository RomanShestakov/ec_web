all: get-deps compile

get-deps:
	./rebar get-deps

compile:
	./rebar compile

clean:
	./rebar clean


# web depends on myapp in web.src, but apparently this doesn't
# mean that myapp is started. Maybe this works if we do a proper release?
run:
	erl -pa ebin ./deps/*/ebin ./deps/*/include \
	-sname nitrogen \
	-setcookie ec_master \
	-eval "application:start(web)."
