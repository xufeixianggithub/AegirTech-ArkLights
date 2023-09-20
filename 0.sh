#!/usr/bin/env bash
{
  root=$(dirname "$0")
  init() {
    declare -A serial
    # serial=([k40]=df7592c8 [l]=localhost:5555 [z9]=z9:5555 [z9v]=z9:5667 )
    # export ANDROID_SERIAL=${serial[${1:-l}]}
    export ANDROID_SERIAL=$1
    adb forward --remove tcp:9095
    adb forward --remove tcp:9090
    adb forward tcp:9095 tcp:9095
    adb forward tcp:9090 tcp:9090
  }
  restartcolor() { # 重启节点精灵，以适应分辨率变更
    adb shell am force-stop com.aojoy.aplug
    sleep 1

    # === no need to start from launcher
    adb shell monkey -p com.aojoy.aplug -c android.intent.category.LAUNCHER 1
    sleep 1

    # === to find the service name
    # adb shell dumpsys activity services aojoy
    # com.aojoy.aplug/com.aojoy.server.CmdAccessibilityService
    # adb shell settings put secure enabled_accessibility_services com.aojoy.aplug/com.aojoy.server.floatwin.FloatService
    # adb shell settings put secure enabled_accessibility_services com.aojoy.aplug/com.aojoy.server.CmdAccessibilityService
    # adb shell settings put secure enabled_accessibility_services com.aojoy.aplug/com.aojoy.server.CmdService
    # sleep 2

    # adb shell am start com.hypergryph.arknights
    # adb shell input keyevent KEYCODE_APP_SWITCH
    # adb shell input keyevent KEYCODE_APP_SWITCH

    #adb shell monkey -p com.hypergryph.arknights -c android.intent.category.LAUNCHER 1
    # sleep 2
  }
  remove() {
    curl 'http://localhost:9090/script/del?name=test' -X 'POST'
  }
  beta() {
    release 'script.lr.beta'
  }
  extract() {
    rm -rf arknights
    rm -rf arknights_extract
    unzip ${1:-arknights.apk} -d arknights
    ./extract.py unpack
  }
  release() {
    # local lr=docs/.vuepress/public/${1:-script.lr}
    local lr=release/${1:-script.lr}
    git add -u
    # cd release
    cp E:/懒人精灵3.8.3/out/main.lr $lr
    # cp ../README.md README.md
    numfmt --to=iec $(stat -c %s $lr)

    local md5=$(md5sum $lr | cut -d' ' -f1)
    echo $md5 >$lr.md5

    cp $lr release/${lr##*/}
    cp $lr.md5 release/${lr##*/}.md5
    git -C release add -u
    git -C release commit --amend --allow-empty-message -m ""
    git -C release push --force

    cp ../dlt/dlt.py dlt.py

    git add -u
    git status

    # # ==== 用js后缀会变快吗，不会
    # cp $lr $lr.js
    # cp $lr.md5 $lr.md5.js

    # git add -A
    # git commit --amend --date=now -m "$md5"
    # git push --force
  }
  stop() {
    i3-msg 'focus left'
    xte 'keydown F6'
    xte 'keyup F6'
    i3-msg 'focus left'
  }
  findr() {
    # 测试不同分辨率下脚本结果
    local option=(
      1080x2400
      720x1280
      1080x1920
      1080x2340
    )
    if [[ -n $1 ]]; then
      option=(${option[$1]})
      shift
    fi
    for ((i = 0; i < ${#option[@]}; ++i)); do
      adb shell wm size ${option[$i]}
      # restartcolor "$@"
      # if [[ $i -eq 0 ]]; then
      #   save "$@"
      # fi
      # run "$@"
    done
  }
  run() {
    i3-msg 'focus left'
    xte 'keydown F6'
    xte 'keyup F6'
    sleep .1
    xte 'keydown F5'
    xte 'keyup F5'
    i3-msg 'focus left'
  }

  save() {
    sed -i -r 's/^(release_date =).+$/\1 "'"$(date +'%m.%d %k:%M')"'"/' main.lua
    local dst_dir=/F/software/懒人精灵3.6.0/script/main
    dst="$dst_dir"/脚本
    mkdir -p $dst
    while IFS= read -r -d '' f; do
      iconv -f UTF-8 -t GB18030 "$f" -o "$dst/$f"
    done < <(find . -maxdepth 1 -type f -name '*.lua' -printf '%P\0')
    dst="$dst_dir"/界面
    mkdir -p $dst
    while IFS= read -r -d '' f; do
      iconv -f UTF-8 -t GB18030 "$f" -o "$dst/$f"
    done < <(find . -maxdepth 1 -type f -name '*.ui' -printf '%P\0')
  }
  saverun() {
    save
    run
  }

  timer() {
    local start=$(date +"%s.%N" -d "${1:-now}")
    local cur
    while :; do
      cur=$(date +"%s.%N")
      printf "\r$(date -d "0 $cur seconds - $start seconds" +"%H:%M:%S")"
      sleep 1
    done
  }

  scrcpy() {
    scrcpy "$@"
  }
  png2rgb() {
    convert "$1" txt:- | tail -n +2 | sed -nr 's/.*(#.{6}).*/\1/p'
  }
  png2alpha() {
    convert "$1" txt:- | tail -n +2 | sed -nr 's/.*,([^,]+)\)$/\1/p'
  }
  dim() {
    # make dim version of skill icon
    local src=${1:-png}
    local dst=${2:-png_noalpha_dim}
    mkdir -p "$dst"
    mogrify -path "$dst" -alpha set -channel A -evaluate multiply 0.4 +channel -alpha remove -alpha off -background '#202020' "$src"/'*.png'
  }
  noalpha() {
    # make noalpha version of skill icon
    local src=${1:-png}
    local dst=${2:-png_noalpha}
    mkdir -p "$dst"
    # mogrify -path "$dst" -alpha remove -alpha off -background '#3D3D3D' "$src"/'*.png'
    mogrify -path "$dst" -alpha remove -alpha off -background '#3D3D3D' "$src"/'*'.png
  }
  noalphaavatar() {
    # make noalpha version of avatar icon
    local src=${1:-'arknights_extract/assets/torappu/dynamicassets/arts/charavatars'}
    local dst=${2:-png_noalpha}
    mkdir -p "$dst"
    for x in $src/'char_*' $src/skins/'char_*.png' $src/elite/'char_*.png'; do
      mogrify -path "$dst" -alpha remove -alpha off -background '#FFFFFF' -resize 36x36 "$x"
    done
  }

  fetchbuildingskill() {
    echo "deprecated, use buildingskill instead"
    exit
    local a="
prts.wiki/images/d/d9/Bskill_meet_spd2.png
prts.wiki/images/a/a0/Bskill_meet_spd1.png
"
    rm -rf png
    rm -rf png_noalpha
    rm -rf release/skill.zip
    mkdir -p png
    cd png
    xargs -I % -P 100 curl -sSLO % <<<"$a"
    cd ..
    noalpha png png_noalpha
    touch png_noalpha/.nomedia
    zip release/skill.zip -q -r -j png_noalpha
    local md5=$(md5sum release/skill.zip | cut -d' ' -f1)
    echo $md5 >release/skill.zip.md5
  }
  buildingskill() {
    
    # local png=$root/arknights_extract/assets/torappu/dynamicassets/arts/building/skills
    local png='../ArkAssetsTool/ArkAssets/spritepack/[unpack]building_ui_buff_skills_h1_0'

    # ==> paint background
    local png_noalpha=png_noalpha
    rm -rf $png_noalpha
    mkdir $png_noalpha
    noalpha $png $png_noalpha

    # ==> remove prefix
    while IFS= read -r -d '' f; do
      mv $png_noalpha/"$f" $png_noalpha/"${f#(Sprite)}"
    done < <(find $png_noalpha -maxdepth 1 -type f -printf '%P\0')

    # ==> only bskill
    find $png_noalpha -type f -not -name 'bskill_*' -delete

    echo -n "==> total "
    ls $png_noalpha | wc -l

    touch $png_noalpha/.nomedia
    # git submodule update --init --recursive --remote
    ./extract.py skillicon2operator >$png_noalpha/skillicon2operator.json

    # local skill=docs/.vuepress/public/skill.zip
    local skill=dist/skill.zip
    mkdir -p "$(dirname "$skill")"
    rm -rf $skill

    zip $skill -q -r -j $png_noalpha
    local md5=$(md5sum $skill | cut -d' ' -f1)
    echo $md5 >$skill.md5

    cp $skill release/${skill##*/}
    cp $skill.md5 release/${skill##*/}.md5

  }

  recruit() {
    ./extract.py recruit
  }

  # ==== 华云外置保活
  hy() {

    # for x in "$@"; do
    local x=$1
    [[ -z $x ]] && continue
    # echo === $x
    adb connect $x >/dev/null
    adb -s $x shell "nohup sh -c 'nc -klp49876 -e sh' > /dev/null 2>&1 &"
    # done
  }

  # === adb 修改模式
  dlt() {
    ../dlt/dlt.py dlt
  }
  m() {
    ../dlt/dlt.py mode "$@"
  }
  u() {
    ../dlt/dlt.js upload --search=$1' ' --path=$D/qq.jpg
  }
  d() {
    # ./dlt.js detail --search=$1' '
    ../dlt/dlt.py DLT detail "$1"
  }
  o() {
    # ./dlt.js order --search=$1' '
    ../dlt/dlt.py DLT order "$@"
  }
  submit() {
    # ./dlt.js order --search=$1' '
    ../dlt/dlt.py DLT submit "$@"
  }
  first() {
    ../dlt/dlt.py DLT first "$@"
  }
  last() {
    ../dlt/dlt.py DLT last "$@"
  }
  over() {
    ../dlt/dlt.py DLT over "$1"
  }
  my() {
    ../dlt/dlt.py DLT my "$@"
  }
  count() {
    ../dlt/dlt.py DLT count "$@"
  }
  check() {
    ../dlt/dlt.py check "$@"
  }
  users() {
    ../dlt/dlt.py users "$@"
  }
  serial() {
    ../dlt/dlt.py DLT all2serial $@
  }
  edu() {
    ../dlt/dlt.py edu $@
  }
  daily() {
    ../dlt/dlt.py daily $@
  }
  a() {
    ../dlt/dlt.py account_exist "$@"
  }
  g() {
    # restart genymotion every 8 hours
    while :; do
      for ((i = 0; i < 3; ++i)); do
        genymotion-player --vm-name 8 &
        sleep 5
        genymotion-player --vm-name 8 --poweroff
        sleep 1
      done

      genymotion-player --vm-name 8 &
      echo == 1
      adb connect 127.0.0.1:5555
      adb -s 127.0.0.1:5555 wait-for-device
      echo == 2
      0 m 0 rg2
      echo == 3
      sleep $((3600*4))
    done
  }
  "$@"
  wait
  exit 0
}
