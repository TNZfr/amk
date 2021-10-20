#!/bin/bash

. _amklib.sh

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 2 ]
then
    echo   ""
    printf "\033[37;44m Syntax \033[m : amk ListDelta Panier SourceCKS\n"
    echo   ""
    echo   "  Panier    : Nom du panier (txt ou csv)"
    echo   "  SourceCKS : Fichier contenant les checksums de reference"
    echo   ""
    exit 1
fi

Panier=$1
SourceCKS=$2

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
CKSTmp=$RepTmp/Checksums_Panier
CKSsrc=$RepTmp/Checksums_Source
ListeDiff=$RepTmp/Diff

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
    echo ""
    echo "\033[1;33;41m +-------------------------------------+ \033[m"
    echo "\033[1;33;41m |   Repertoire RACINE indisponible    | \033[m"
    echo "\033[1;33;41m | Fabrication de l'archive impossible | \033[m"
    echo "\033[1;33;41m +-------------------------------------+ \033[m"
    rm -rf $RepTmp ; exit 1
fi

# 1. Generation de la liste des fichiers
# 2. Generation des checksums
# --------------------------------------
printh "\033[34;47m Checksum generation ... \033[m"
GenerateCheckSum.sh $Panier $CKSTmp > /dev/null 2>&1

NbCKS=$(cat $CKSTmp|wc -l)
printh "$NbCKS checksum(s) found."

if [ $NbCKS -eq 0 ]
then
    rm -rf $RepTmp
    exit 0
fi

# 3. Preparation de la liste de reference
# ---------------------------------------
printh "\033[34;47m Source checksum preparation ... \033[m"
> $CKSsrc
cat $SourceCKS | while read Line
do
    echo "${Line}]" >> $CKSsrc
done

# 4. Recherches des mises a jour
# ------------------------------
printh "\033[34;47m Searching updates ... \033[m"
cd $RootTGZ
> $ListeDiff
cat $CKSTmp | while read Line
do
    Source_CKS=$(grep "${Line}]" $CKSsrc)

    if [ "$Source_CKS" == "" ]
    then
	ls -l "$(echo $Line | cut -d' ' -f3)"
	echo "$Line" > $ListeDiff
    fi
done
printh "$(cat $ListeDiff|wc -l) difference(s) found."

# Nettoyage du repertoire temporaire
rm -rf $RepTmp

echo ""
exit $Status
