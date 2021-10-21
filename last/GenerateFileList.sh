#!/bin/bash

. _amklib.sh

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 2 ]
then
    echo   ""
    printf "\033[37;44m Syntax \033[m : amk GenerateFileList Panier Liste\n"
    echo   ""
    echo   "  Panier : Nom du panier (txt ou csv)"
    echo   "  Liste  : Fichier contenant la liste"
    echo   ""
    exit 1
fi

Panier=$1
FileList=$2

if [ ! -f $Panier ]
then
    echo   ""
    printf "\033[31;47m $Panier not found \033[m\n"
    echo   ""
    exit 1
fi

RepTmp=/tmp/GenTGZ-$$
mkdir $RepTmp
PanierTmp=$RepTmp/Panier
ExclusionTmp=$RepTmp/Exclude
ContenuTmp=$RepTmp/Contenu
PurgeTmp=$RepTmp/Purge

# Definition absolue du fichier cible
# -----------------------------------
if [ ${FileList:0:1} != "/" ]
then
    CurrentDir=$PWD
    cd $(dirname $FileList); FileList=$PWD/$(basename $FileList)
    cd $CurrentDir
fi

# Conversion et passage en format UNIX (vs format DOS)
# ------------------------------------
if [ ${Panier%.csv} != $Panier ] # c'est un fichier CSV
then
    cat $Panier | sed 's/;/ /g' | sed 's/\r//g' | while read Line
    do
	echo $Line >> $PanierTmp
    done    
else
    cat $Panier | sed 's/\r//g' | while read Line
    do
	echo $Line >> $PanierTmp
    done
fi

# Recuperation de la racine
# -------------------------
RootTGZ=$(eval echo $(grep "^ROOT " $PanierTmp|tail -1)|cut -d' ' -f2)
if [ ! -d $RootTGZ ]
then
    echo   ""
    printf "\033[1;33;41m +------------------------------------+ \033[m\n"
    printf "\033[1;33;41m |   Repertoire RACINE indisponible   | \033[m\n"
    printf "\033[1;33;41m | Fabrication de la liste impossible | \033[m\n"
    printf "\033[1;33;41m +------------------------------------+ \033[m\n"
    rm -rf $RepTmp
    exit 1
fi

# Generation des listes
# ---------------------
ExecuteModule $PanierTmp $RootTGZ
[ $? -ne 0 ] && rm -rf $RepTmp && exit 1

grep "^EXCLUDE " $PanierTmp|cut -d' ' -f2-|sed 's/ /\n/g' > $ExclusionTmp
grep "^ADD "     $PanierTmp|cut -d' ' -f2-|sed 's/ /\n/g' > $ContenuTmp
grep "^PURGE "   $PanierTmp|cut -d' ' -f2-|sed 's/ /\n/g' > $PurgeTmp

NbExclusion=$(echo $(cat $ExclusionTmp|wc -l))
NbContenu=$(  echo $(cat $ContenuTmp  |wc -l))
NbPurge=$(    echo $(cat $PurgeTmp    |wc -l))

# 1. Purge des repertoires
# ------------------------
if [ $NbPurge -eq 0 ]
then
    printh "\033[34;47m No purge needed \033[m"
else
    CurrentDir=$PWD
    cd $RootTGZ
    printh "\033[34;47m Purging directories ... \033[m"
    cat $PurgeTmp|while read Line
    do
	printf " %3d files from $Line\n" $(ls -l $Line 2>/dev/null|grep "^-r"|wc -l)
	rm -f $Line
    done
    cd $CurrentDir
fi

# 2. Generation de l'archive TGZ
# ------------------------------
if [ $NbContenu -eq 0 ]
then
    printh "No archive generated (empty list)"
    rm -rf $RepTmp ; exit 0
fi

printh "\033[34;47m List generation ... \033[m"
cd $RootTGZ
if [ $NbExclusion -gt 0 ]
then
    tar cf             -             \
	--exclude-from $ExclusionTmp \
	$(cat          $ContenuTmp)  | tar tf - > $FileList
else
    tar cf             -             \
	$(cat          $ContenuTmp)  | tar tf - > $FileList
fi

Status=$?

# Nettoyage du repertoire temporaire
rm -rf $RepTmp

printh "Done, return code : $Status"
echo   ""
exit $Status
