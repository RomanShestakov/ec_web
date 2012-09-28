#!/bin/sh
cd `dirname $0`

exec erl -pa $PWD/ebin -pa $PWD/deps/*/ebin -name ec_web"@"$HOSTNAME \
    -setcookie rs -s web_app start -config ebin/ec_web
