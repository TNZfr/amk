#!/bin/bash

#------------------------------------------------------------------------------------------------
# main
#

if [ "$AMK_ACCOUNTING" = "" ]
then
    print ""
    print "*** Accounting disabled, no files to be saved. ***"
    print ""
    exit 0
fi

AMK_LOGTGZ=AMKLOG-$(uname -n)-${LOGNAME}-$(date +%Y%m%d-%Hm%Mm%Ss).tgz

cd $AMK_ACCOUNTING
tar cfz $AMK_LOGTGZ *.log
[ $? -eq 0 ] && rm -f *.log

print ""
print "Archive file \033[33;44m $AMK_ACCOUNTING/$AMK_LOGTGZ \033[m created."
print ""

exit 0
