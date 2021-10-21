#!/bin/bash

. _amklib.sh

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 1 ]
then
    echo ""
    echo "\033[37;44m Syntax \033[m : amk Infos Panier"
    echo ""
    echo "  Panier ... : Nom du panier (txt ou csv)"
    echo ""
    exit 1
fi

Panier=$1
Detail=0
[ $# -gt 1 ] && [ $(echo $2|tr [:lower:] [:upper:]) = "FULL" ] && Detail=1

if [ ! -f $Panier ]
then
    echo ""
    printf "\033[31;47m $Panier not found \033[m\n"
    echo ""
    exit 1
fi

RepTmp=/tmp/InfTGZ-$$
mkdir $RepTmp
PanierTmp=$RepTmp/Panier
ExclusionTmp=$RepTmp/Exclusion
ContenuTmp=$RepTmp/Contenu
PurgeTmp=$RepTmp/Purge

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
    printf "\033[1;33;41m +----------------------------------+ \033[m\n"
    printf "\033[1;33;41m |  Repertoire RACINE indisponible  | \033[m\n"
    printf "\033[1;33;41m | Comptage des fichiers impossible | \033[m\n"
    printf "\033[1;33;41m +----------------------------------+ \033[m\n"
else
    cd $RootTGZ
fi

# Generation des listes
# ---------------------
ExecuteModule $PanierTmp $RootTGZ
[ $? -ne 0 ] && rm -rf $RepTmp && exit 1

grep "^EXCLUDE " $PanierTmp|cut -d' ' -f2-|sed 's/ /\n/g' > $ExclusionTmp
grep "^ADD "     $PanierTmp|cut -d' ' -f2-|sed 's/ /\n/g' > $ContenuTmp
grep "^PURGE "   $PanierTmp|cut -d' ' -f2-|sed 's/ /\n/g' > $PurgeTmp

NbPurge=$(   cat $PurgeTmp    |wc -l)
NbEnrExclu=$(cat $ExclusionTmp|wc -l)
NbEnrArchi=$(cat $ContenuTmp  |wc -l)

if [ $NbEnrExclu -gt 0 ]
then
    NbRepExclu=$(find $(cat $ExclusionTmp) -type d 2>/dev/null|wc -l)
    NbFicExclu=$(find $(cat $ExclusionTmp) -type f 2>/dev/null|wc -l)
fi

if [ $NbEnrArchi -gt 0 ]
then
    NbRepArchi=$(find $(cat $ContenuTmp  ) -type d 2>/dev/null|wc -l)
    NbFicArchi=$(find $(cat $ContenuTmp  ) -type f 2>/dev/null|wc -l)
fi


# Affichage des informations collectees
# -------------------------------------
echo ""
printf "\033[37;44m Fichier PANIER    \033[m : $Panier\n"
printf "\033[37;44m Repertoire RACINE \033[m : $RootTGZ\n"
echo ""
#-------------------------------------------------------------------------------
if [ $NbPurge -gt 0 ]
then
    printf "\033[34;47m Purge     \033[m %3d enreg.\n" $NbPurge
    MaxLength=$(cat $PurgeTmp|wc -L)
else
    printf "\033[34;47m Purge     \033[m Aucune\n"
fi

if [ $Detail -eq 1 ]
then
    cat $PurgeTmp | while read Line
    do
	NbFichier=$(echo $(ls -l $Line 2>/dev/null|grep "^-r"|wc -l))
	printf "            %-${MaxLength}s %4d fichier(s)\n" "$Line" $NbFichier
    done
    echo ""
fi
#-------------------------------------------------------------------------------
if [ $NbEnrExclu -gt 0 ]
then
    printf "\033[34;47m Exclusion \033[m %3d enreg., %3d repertoire(s), %4d fichier(s)\n" \
	   $NbEnrExclu $NbRepExclu $NbFicExclu
    MaxLength=$(cat $ExclusionTmp|wc -L)
else
    printf "\033[34;47m Exclusion \033[m Aucune\n"
fi

if [ $Detail -eq 1 ]
then
    cat $ExclusionTmp | while read Line
    do
	NbFichier=0
	Type="\033[0;31;47mAbs\033[m"
	[ -d $Line ] && Type=Rep && NbFichier=$(echo $(find $Line -type f 2>/dev/null|wc -l))
	[ -f $Line ] && Type=Fic && NbFichier=$(echo $(ls -1 $Line 2>/dev/null|wc -l))
	[ -L $Line ] && Type=Lnk

	if [ $NbFichier -gt 1 ]
	then
	    printf "        \033[1m$Type\033[m %-${MaxLength}s %4d fichiers\n" "$Line" $NbFichier
	else
	    printf "        \033[1m$Type\033[m %s\n" "$Line"
	fi
    done
    echo ""
fi
#-------------------------------------------------------------------------------
if [ $NbEnrArchi -gt 0 ]
then
    printf "\033[34;47m Archive   \033[m %3d enreg., %3d repertoire(s), %4d fichier(s)\n" \
	   $NbEnrArchi $NbRepArchi $NbFicArchi
    MaxLength=$(cat $ContenuTmp|wc -L)
else
    printf "\033[34;47m Archive   \033[m Vide\n"
fi

if [ $Detail -eq 1 ]
then
    cat $ContenuTmp | while read Line
    do
	NbFichier=0
	[ -d $Line ] && Type=Rep && NbFichier=$(echo $(find $Line -type f 2>/dev/null|wc -l))
	[ -f $Line ] && Type=Fic && NbFichier=$(echo $(ls -1 $Line 2>/dev/null|wc -l))
	[ -L $Line ] && Type=Lnk

	if [ $NbFichier -gt 1 ]
	then
	    printf "        \033[1m$Type\033[m %-${MaxLength}s %4d fichiers\n" "$Line" $NbFichier
	else
	    printf "        \033[1m$Type\033[m %s\n" "$Line"
	fi
    done
fi
#-------------------------------------------------------------------------------
echo ""

rm -rf $RepTmp
exit $Status
