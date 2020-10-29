#!/bin/bash

# 環境変数定義
_PARAM_CNT=$#
_INPUT_ACTION=`echo $1 | tr [:upper:] [:lower:]`
_TAG_NAME=$2

declare -A _DIC_ACTION
_DIC_ACTION["start"]="start"
_DIC_ACTION["stop"]="stop"

# 関数定義
search_instance_id() {
	_INS_ID=`aws ec2 describe-instances --filter "Name=tag:Name,Values=$_TAG_NAME" --query 'Reservations[].Instances[].InstanceId' --output=text`
	if [ -z $_INS_ID ]; then
		echo "---- 該当インスタンスは存在しないため、プログラムを終了します。"
		echo "---- Nameタグが設定されているか確認してください。"
		exit 1
	fi
}

check_parameter() {
	if [ $_PARAM_CNT -ne 2 ]; then
		echo "---- 正しいパラメータが設定されていません。"
		exit 1
	fi
}

pre_processing() {
	_PRE_STATE=`aws ec2 describe-instances --instance-ids $_INS_ID | jq -r '.Reservations[].Instances[].State.Name'`

	# 起動前、ステータスチェック
	if [ ${_DIC_ACTION[$_INPUT_ACTION]} = "start" ]; then
		if [ $_PRE_STATE = "running" ]; then
			echo "---- すでに起動中です。プログラムを終了します。"
			exit 1
		fi
	# 停止前、ステータスチェック
	elif [ ${_DIC_ACTION[$_INPUT_ACTION]} = "stop" ]; then
		if [ $_PRE_STATE = "stopped" ]; then
			echo "---- すでに停止中です。プログラムを終了します。"
			exit 1
		fi
	else
		echo "---- 実装されてない機能です。プログラムを終了します。"
	fi
}


main() {
	# パラメータ数チェック
	check_parameter
	# インスタンスID取得
	search_instance_id
	# 前処理プロセス
	pre_processing
	# メイン処理
	if [ $_INPUT_ACTION = "start" ]; then
		
		# 起動
		aws ec2 start-instances --instance-ids $_INS_ID
		echo "---- インスタンスが起動中です。少しお待ちください。"

		# timeout戻り値
		# 正常 → 0
		# 異常 → 124
		timeout 300 aws ec2 wait instance-running --instance-ids $_INS_ID
                if [ $? -eq 0 ]; then
                        echo -e "---- 電源ON \e[32;1m[ OK ]\e[m"
                else
                        echo -e "---- 電源ON \e[31;1m[ ERROR ] (timeoutの可能性があります。)\e[m"
                        echo "---- 起動に失敗しました。プログラムを終了します。"
                        exit 1
                fi


		# ステータスチェック
		timeout 300 aws ec2 wait instance-status-ok --instance-ids $_INS_ID
                if [ $? -eq 0 ]; then
                        echo -e "---- ステータスチェック \e[32;1m[ OK ]\e[m"
		else
                        echo -e "---- ステータスチェック \e[31;1m[ ERROR ] (timeoutの可能性があります。)\e[m"
                        echo "---- 起動に失敗しました。プログラムを終了します。"
                        exit 1
                fi

		# 起動確認
		aws ec2 describe-instance-status --instance-ids $_INS_ID | jq '.InstanceStatuses[] | {InstanceId, InstanceState: .InstanceState.Name, SystemStatus: .SystemStatus.Status, InstanceStatus: .InstanceStatus.Status}'

	elif [ $_INPUT_ACTION = "stop" ]; then
	
		# 停止
		aws ec2 stop-instances --instance-ids $_INS_ID
		echo "---- インスタンスが停止中です。少しお待ちください。"


		# timeout戻り値
		# 正常 → 0
		# 異常 → 124
		timeout 300 aws ec2 wait instance-stopped --instance-ids $_INS_ID
                if [ $? -eq 0 ]; then
                        echo -e "---- 電源OFF \e[32;1m[ OK ]\e[m"
                else
                        echo -e "---- 電源OFF \e[31;1m[ ERROR ] (timeoutの可能性があります。)\e[m"
                        echo "---- 起動に失敗しました。プログラムを終了します。"
                        exit 1
                fi


		# 停止確認
		aws ec2 describe-instances --instance-ids $_INS_ID | jq '.Reservations[].Instances[] | {InstanceId, InstanceState: .State.Name}'
	fi
	

}

# 実行
main
