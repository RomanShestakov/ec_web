#!/bin/sh
cd `dirname $0`
exec erl -pa $PWD/apps/*/ebin -pa $PWD/deps/*/ebin -name ec_cli@127.0.0.1 \
    -setcookie ec_master \
    -eval 'application:start(view)'
