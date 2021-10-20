#!/bin/bash
#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 1 ]
then
    print ""
    print "\033[37;44m Syntax \033[m : amk FullInfos Panier"
    print ""
    print "  Panier ... : Nom du panier (txt ou csv)"
    print ""
    exit 1
fi

Infos.sh $1 FULL
exit $?
