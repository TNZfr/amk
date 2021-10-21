#!/bin/bash

# Parametres recus
# - Racine archive (clause ROOT)
# - Parametres definis dans le panier 

Racine=$1
Version=$2

rm $HOME/bin/amk
ln -s amk$Version/Main.sh $HOME/bin/amk

echo "ADD bin/amk"
echo "ADD bin/amk$Version"
echo "PURGE bin/amk$Version/*~"
