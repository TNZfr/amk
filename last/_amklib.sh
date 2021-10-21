#!/bin/bash

#------------------------------------------------------------------------------------------------
function printh
{
    printf "$(date +%d/%m/%Y-%Hh%Mm%Ss) : $*\n"
}

#------------------------------------------------------------------------------------------------
function ExecuteModule
{
    PanierTmp=$1
    RootTGZ=$2

    grep "^MODULE " $PanierTmp | while read Enreg
    do
	Module=$(eval echo $Enreg|cut -d' ' -f2 )
	Parametres=$( echo $Enreg|cut -d' ' -f3-)

	$Module $RootTGZ $Parametres >> $PanierTmp.AjoutModule
	[ $? -ne 0 ] && return 1
    done
    grep -e ^ADD -e ^EXCLUDE -e ^PURGE $PanierTmp.AjoutModule >> $PanierTmp

    return 0
}
