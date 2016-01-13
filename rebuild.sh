#!/bin/sh

MAX_CNT=3
curr_build_id=$CIRCLE_BUILD_NUM
# curr_build_id=23
build_cnt=0

# 現在のリトライ回数を取得する

# 前回のビルド番号
prev_build_id=$(curl -s https://circleci.com/api/v1/project/ikemonn/circleciTest/$curr_build_id | sed -e '1,1d' | jq '.retry_of')
echo prev_build_id $prev_build_id
# nullかビルド番号が返ってくるので、数値か文字列かを判定
expr "$prev_build_id" + 1 >/dev/null 2>&1
if [ $? -lt 2 ]; then
  echo "ビルド番号を取得 " $prev_build_id
  echo "前回までのビルド回数を取得します。"
  ARTIFACTS_NAME="buildCnt"
  # "buildCnt"が含まれているデータを取得し、artifactsのURLを取得
  artifact_url=$(curl -s https://circleci.com/api/v1/project/ikemonn/circleciTest/$prev_build_id/artifacts?circle-token=$CIRCLE_TOKEN|sed -e '1,1d'|jq -r '.[] | select(contains({path:"buildCnt"})) | .url')
  echo URL " $artifact_url"
  # 正しく通信できているか確認(exit codeが0以外だとエラー)
  exit_code=$(curl -f -I $artifact_url)
  # echo exit_code " $exit_code"
  if [ $? -eq 0 ];then
    echo "curlできているので、ビルド回数を取得"
    build_cnt=$(curl -s $artifact_url)
  else
    echo "curl失敗です"
    # TODO: Slackに通知
  fi
else
  echo "ビルド番号を取得できませんでした"
fi

echo build_cnt $build_cnt

# 取得できれば指定回数以下かチェック、指定回数以下なら+1回をfileに書き込む & retry
# 数値か判定
expr "$build_cnt" + 1 >/dev/null 2>&1
if [ $? -ge 2 ]; then
  echo "buildCntの値が数値ではありません"
  # TODO: Slackに通知
fi

if [ "$build_cnt" -lt "$MAX_CNT" ]; then
  echo `let $build_cnt++` > $CIRCLE_ARTIFACTS/buildCnt.txt
  # TODO: リトライ処理書く
  echo "リトライします"
else
  echo "リトライしません"
fi

echo "終了"
exit 0
