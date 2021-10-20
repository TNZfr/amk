#!/bin/bash

#------------------------------------------------------------------------------------------------
function AcctFile
{
CommandName=$1

    # --------------------------------
    # Gestion de la LOG de la commande
    # --------------------------------
    AMK_FICACC="/dev/null"
    if [ -n "$AMK_ACCOUNTING" ] && [ -d $AMK_ACCOUNTING ]
    then
	AMK_FICACC=$AMK_ACCOUNTING/$(date +%Y%m%d-%Hh%Mm%Ss)-$CommandName.log
	printf "\n\033[33;44m Command \033[m : clussh $Commande $Parametre\n" > $AMK_FICACC
	chmod a+rw $AMK_FICACC
    fi
}

#------------------------------------------------------------------------------------------------
function LoadConfiguration
{
    AMK_RC=~/.amk/_amkrc.ksh

    if [ ! -f $AMK_RC ]
    then
	echo   ""
	echo   " +------------------------------------------------------+"
	printf " | \033[1;5;33;41m        *** Missing configuration file ***          \033[m |"
	echo   " +------------------------------------------------------+"
	echo   " | Run following command to solve the issue :           |"
	printf " | \033[34;47mtgz Configure\033[m                                        |"
	echo   " +------------------------------------------------------+"
	echo   ""
	exit
    fi

    # Chargement de la configuration
    . $AMK_RC
}

#-------------------------------------------------------------------------------
function RunCommand
{
    CommandName=$1

    if [ $# -eq 2 ] && [ $2 = NO_ACCOUNTING ]
    then
	AMK_FICACC="/dev/null"
    else
	# Mise en oeuvre accounting
	AcctFile ${CommandName}
    fi

    if [ $AMK_FICACC = "/dev/null" ]
    then
	${CommandName}.sh $Parametre
	Status=$?
    else
	StatusFile=/tmp/status-$$
	(${CommandName}.sh $Parametre;echo $? > $StatusFile) | tee -a $AMK_FICACC
	Status=$(cat $StatusFile; rm -f $StatusFile)
    fi

    return $Status
}

#-------------------------------------------------------------------------------
# main
#

if [ $# -eq 0 ]
then
    echo   ""
    printf "\033[37;44m Syntax \033[m : amk Command Parameters ...\n"
    echo   ""
    printf "\033[34;47mTool management\033[m\n"
    echo              "---------------"
    echo   "Infos      (I): Display informations on a basket file"
    echo   "FullInfos (FI): Display informations on a basket file"
    echo   "ListDelta (LD): List delta between basket and checksum list"
    echo   ""
    printf "\033[34;47mPackage Generation\033[m\n"
    echo              "------------------\n"
    echo   "Generate         (GEN): Generate TGZ archive from basket file"
    echo   "GenerateFileList (GFL): Generate file list of selected basket"
    echo   "GenerateCheckSum (GCS): Generate checksum of target files from basket"
    echo   "BuildDelta        (BD): Build delta between basket and checksum list"
    echo   ""
    exit 0
fi

# ------------------------------------------------------
# Cas des AIX : rajout du repertoire GNU quand il existe
# ------------------------------------------------------
AIX_GNU_BIN=/opt/freeware/bin
[ -d $AIX_GNU_BIN ] && export PATH=$AIX_GNU_BIN:$PATH

# -------------------------------------
# Definition du repertoire des binaires
# -------------------------------------
export AMK_EXE=$(dirname $(readlink -f $0))
export PATH=$AMK_EXE:$PATH

# ---------------------
# Parsing des commandes
# ---------------------
Parametre=""
Commande=$(echo $1|tr [:upper:] [:lower:])
[ $# -gt 1 ] && Parametre="$(echo $*|cut -f2- -d' ')"

# Cette commande cree le fichier _tgzrc.ksh
# --------------------------------------------
if [ "$Commande" = "configure" ]
then
    Configure.sh $Parametre
    return $?
fi

# --------------------------------
# Chargement des variables locales
# --------------------------------
#LoadConfiguration

case $Commande in

    "generate" |"gen") RunCommand Generate ;;
    "infos"    |"i"  ) RunCommand Infos    ;;
    "fullinfos"|"fi" ) RunCommand FullInfos;;

    "generatefilelist"|"gfl") RunCommand GenerateFileList ;;
    "generatechecksum"|"gcs") RunCommand GenerateCheckSum ;;
    "listdelta"       |"ld")  RunCommand ListDelta        ;;
    "builddelta"      |"bd")  RunCommand BuildDelta       ;;

    # Les autres commandes
    # --------------------
    "savelog"|"sl") RunCommand SaveLog NO_ACCOUNTING;;

    *)
	echo "Commande $1 inconnue."
esac

exit $Status
