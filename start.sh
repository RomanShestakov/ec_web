#!/bin/sh
cd `dirname $0`
exec erl -pa $PWD/ebin -pa $PWD/deps/*/ebin -pa $PWD/deps/*/include \
    -sname nitrogen \
    -setcookie ec_master \
    -eval 'application:start(ec_web)'
