#!/bin/sh
cd `dirname $0`
<<<<<<< HEAD
exec erl -pa $PWD/ebin -pa $PWD/deps/*/ebin -name ec_web"@"$HOSTNAME \
    -setcookie rs -s web_app start -config ebin/ec_web
=======

exec erl -pa $PWD/apps/*/ebin -pa $PWD/deps/*/ebin -name ec_web"@"$HOSTNAME \
    -setcookie rs \
    -eval 'application:start(view)'
    -config ebin/view
>>>>>>> 3997cc61228dc9660a3cc86e0db86aa7c7340c6c
