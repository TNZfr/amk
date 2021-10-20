#!/bin/bash

. _amklib.sh

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 3 ]
then
    echo ""
    printf "\033[37;44m Syntax \033[m : amk BuildDelta Panier SourceCKS ArchiveTGZ\n"
    echo ""
    echo "  Panier    : Nom du panier (txt ou csv)"
    echo "  SourceCKS : Fichier contenant les checksums de reference"
    echo "  ArchiveTGZ: Archive recevant les fichiers mis a jour"
    echo ""
    exit 1
fi

Panier=$1
SourceCKS=$2
ArchiveTGZ=$3

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
CKSTmp=$RepTmp/Checksums_Panier
CKSsrc=$RepTmp/Checksums_Source
ListeTGZ=$RepTmp/FileList

# Definition du chemin complet de le fichier de sortie
# ----------------------------------------------------
if [ $(echo $ArchiveTGZ|cut -c1) != '/' ]
then
    CurrentDir=$PWD
    cd $(dirname $ArchiveTGZ)
    ArchiveTGZ=$PWD/$(basename $ArchiveTGZ)
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
    printf "\033[1;33;41m +-------------------------------------+ \033[m\n"
    printf "\033[1;33;41m |   Repertoire RACINE indisponible    | \033[m\n"
    printf "\033[1;33;41m | Fabrication de l'archive impossible | \033[m\n"
    printf "\033[1;33;41m +-------------------------------------+ \033[m\n"
    rm -rf $RepTmp ; exit 1
fi

# 1. Generation de la liste des fichiers
# --------------------------------------
printh "\033[34;47m Checksum generation ... \033[m"
GenerateCheckSum.sh $Panier $CKSTmp > /dev/null 2>&1

NbCKS=$(cat $CKSTmp|wc -l)
printh "$NbCKS checksum(s) found."

# 2. Generation des checksums
# ---------------------------
if [ $NbCKS -eq 0 ]
then
    rm -rf $RepTmp ; exit 0
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
> $ListeTGZ
cd $RootTGZ
cat $CKSTmp | while read Line
do
    Source_CKS=$(grep "${Line}]" $CKSsrc)

    if [ "$Source_CKS" == "" ]
    then
	echo $Line | cut -d' ' -f3- >> $ListeTGZ
	((NbFile += 1))
    fi
done

NbFile=$(cat $ListeTGZ|wc -l)
printh "$NbFile difference(s) found."
if [ $NbFile -eq 0 ]
then
    rm -rf $RepTmp ; exit 0
fi

# 5. Generation de l'archive TGZ
# ------------------------------
printh "\033[34;47m Archive generation ... \033[m"
    tar cfz            $ArchiveTGZ   \
	--directory    $RootTGZ      \
	$(cat          $ListeTGZ)
Status=$?

# Nettoyage du repertoire temporaire
rm -rf $RepTmp

[ $Status -ne 0 ] && printh "Done, return code : $Status" && exit $Status

# 6. Generation de la liste des fichiers
# --------------------------------------
ArchiveLST=${ArchiveTGZ%.tgz}.lst
printh "Content generation : $(basename $ArchiveLST) ..."
tar tvfz $ArchiveTGZ > $ArchiveLST
Status=$?
[ $Status -ne 0 ] && printh "Done, return code : $Status" && exit $Status

# 7. Generation de la liste des checksums
# ---------------------------------------
ArchiveCKS=${ArchiveTGZ%.tgz}.cks
> $ArchiveCKS
printh "Checksum generation : $(basename $ArchiveCKS) ..."
cd $RootTGZ
tar tfz $ArchiveTGZ | while read Line 
do
    cksum $Line >> $ArchiveCKS 2>/dev/null &
done
wait

printh "Done, return code : $Status"
echo  ""
exit $Status
