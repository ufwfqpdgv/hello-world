#!/bin/sh

echo "exec gp global motion `date`">>~/mine/crontab.log
cd ~/mine/hello-world && git pull && git add . && git commit -m "new" && git push origin master
