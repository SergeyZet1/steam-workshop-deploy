#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

CURRENT_PWD=$(pwd)

steamdir=${STEAM_HOME:-$HOME/.local/share/Steam}
# this is relative to the action
contentroot=$CURRENT_PWD/$rootPath

manifest_path=$CURRENT_PWD/workshop.vdf

echo ""
echo "#################################"
echo "#    Generating GMA #"
echo "#################################"
echo ""


cp /root/gma.lua $contentroot/gma.lua

cd $contentroot

lua5.3 gma.lua $itemId.gma addon.json

cd $CURRENT_PWD

echo ""
echo "#################################"
echo "#    Generating Item Manifest   #"
echo "#################################"
echo ""

cat << EOF > "workshop.vdf"
"workshopitem"
{
    "appid" "$appId"
    "publishedfileid" "$itemId"
    "contentfolder" "$contentroot/$itemId.gma"
    "changenote" "$changeNote"
}
EOF

cat workshop.vdf
echo ""

if [ ! -n "$configVdf" ]; then
  echo ""
  echo "#################################"
  echo "#     Using SteamGuard TOTP     #"
  echo "#################################"
  echo ""

  steamcmd +set_steam_guard_code "$steam_totp" +login "$steam_username" "$steam_password" +quit;

  ret=$?
  if [ $ret -eq 0 ]; then
      echo ""
      echo "#################################"
      echo "#        Successful login       #"
      echo "#################################"
      echo ""
  else
        echo ""
        echo "#################################"
        echo "#        FAILED login           #"
        echo "#################################"
        echo ""
        echo "Exit code: $ret"

        exit $ret
  fi
else
  if [ ! -n "$configVdf" ]; then
    echo "Config VDF input is missing or incomplete! Cannot proceed."
    exit 1
  fi

  steam_totp="INVALID"

  echo ""
  echo "#################################"
  echo "#    Copying SteamGuard Files   #"
  echo "#################################"
  echo ""

  echo "Steam is installed in: $steamdir"

  mkdir -p "$steamdir/config"

  echo "Copying $steamdir/config/config.vdf..."
  echo "$configVdf" | base64 -d > "$steamdir/config/config.vdf"
  chmod 777 "$steamdir/config/config.vdf"

  echo "Finished Copying SteamGuard Files!"
  echo ""

  echo ""
  echo "#################################"
  echo "#        Test login             #"
  echo "#################################"
  echo ""

  steamcmd +login "$steam_username" +quit;

  ret=$?
  if [ $ret -eq 0 ]; then
      echo ""
      echo "#################################"
      echo "#        Successful login       #"
      echo "#################################"
      echo ""
  else
        echo ""
        echo "#################################"
        echo "#        FAILED login           #"
        echo "#################################"
        echo ""
        echo "Exit code: $ret"

        exit $ret
  fi
fi

echo ""
echo "#################################"
echo "#        Uploading item         #"
echo "#################################"
echo ""

steamcmd +login "$steam_username" +workshop_build_item "$manifest_path" +quit || (
    echo ""
    echo "#################################"
    echo "#             Errors            #"
    echo "#################################"
    echo ""
    echo "Listing current folder and root path"
    echo ""
    ls -alh
    echo ""
    ls -alh "$rootPath" || true
    echo ""
    echo "Listing logs folder:"
    echo ""
    ls -Ralph "$steamdir/logs/"

    for f in "$steamdir"/logs/*; do
      if [ -e "$f" ]; then
        echo "######## $f"
        cat "$f"
        echo
      fi
    done

    echo ""
    echo "Displaying error log"
    echo ""
    cat "$steamdir/logs/stderr.txt"
    echo ""
    echo "Displaying bootstrapper log"
    echo ""
    cat "$steamdir/logs/bootstrap_log.txt"

    exit 1
  )

echo "manifest=${manifest_path}" >> $GITHUB_OUTPUT
