#!/bin/bash

. _amklib.sh

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 2 ]
then
    echo ""
    printf "\033[37;44m Syntax \033[m : amk GenerateCheckSum Panier ListeCKS\n"
    echo ""
    echo "  Panier    : Nom du panier (txt ou csv)"
    echo "  ListeCSK  : Fichier contenant les checksums"
    echo ""
    exit 1
fi

Panier=$1
ListeCKS=$2

if [ ! -f $Panier ]
then
    echo ""
    printf "\033[31;47m $Panier not found \033[m\n"
    echo ""
    exit 1
fi

RepTmp=/tmp/GenTGZ-$$
mkdir $RepTmp
PanierTmp=$RepTmp/Panier
ContenuTmp=$RepTmp/Contenu

# Definition du chemin complet de le fichier de sortie
# ----------------------------------------------------
if [ $(echo $ListeCKS|cut -c1) != '/' ]
then
    CurrentDir=$PWD
    cd $(dirname $ListeCKS)
    ListeCKS=$PWD/$(basename $ListeCKS)
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
    echo ""
    printf "\033[1;33;41m +------------------------------------+ \033[m\n"
    printf "\033[1;33;41m |   Repertoire RACINE indisponible   | \033[m\n"
    printf "\033[1;33;41m | Fabrication de la liste impossible | \033[m\n"
    printf "\033[1;33;41m +------------------------------------+ \033[m\n"
    rm -rf $RepTmp
    exit 1
fi

# 1. Generation de la liste des fichiers
# --------------------------------------
printh "\033[34;47m File list generation ... \033[m"
GenerateFileList.sh $Panier $ContenuTmp > /dev/null 2>&1

NbFile=$(cat $ContenuTmp|wc -l)
printh "$NbFile file(s) found."

# 2. Generation des checksums
# ---------------------------
if [ $NbFile -eq 0 ]
then
    rm -rf $RepTmp
    exit 0
fi

printh "\033[34;47m Checksum generation ... \033[m"
> $ListeCKS
cd $RootTGZ
cat $ContenuTmp | while read Line
do
    cksum "$Line" >> $ListeCKS 2>/dev/null &
done
wait

# Nettoyage du repertoire temporaire
rm -rf $RepTmp

printh "Done"
echo  ""
exit $Status
