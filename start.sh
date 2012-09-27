#!/bin/sh
cd `dirname $0`

exec erl -pa $PWD/apps/*/ebin -pa $PWD/deps/*/ebin -name ec_web"@"$HOSTNAME \
    -setcookie rs \
    -eval 'application:start(view)'
    -config ebin/view
