#!/bin/bash

# 0. Output Manual
output_man() {
        echo ""
        echo "----------------------------------------------------------------------------------"
        echo "|                               SgManagementTool_v1                              |"
        echo "+--------------------------------------------------------------------------------+"
        echo "| *SELECT MODE*                                                                  |"
        echo "|<1> All security group names and IDs                                            |"
        echo "|<2> Details of each security group                                              |"
        echo "|<3> Associated instance output                                                  |"
        echo "|<4> Associated instance output .csv file                                        |"
        echo "|<5> All associated instance output .csv file                                    |"
        echo "|<6> Manual                                                                      |"
        echo "|<q> exit                                                                        |"
        echo "+--------------------------------------------------------------------------------+"
        echo -n ": "
}
 
# Set the vpc-id ( Only get_sg_details() is used )
_VPC_ID=XXXX
 
# 1. Get the entire list
#
# ex)
#-------------------------------------------------------------------
#|                     DescribeSecurityGroups                      |
#+----------------------------------------+------------------------+
#|  default                               |  sg-00e020181c4d44894  |
#|  CloudEndure Replicator Security Group |  sg-048df9b0d755ed9e9  |
#|  launch-wizard-1                       |  sg-06a06a2bfd15af939  |
#|  default                               |  sg-078511d3b0e1406d7  |
#|  resolver-test                         |  sg-0a28f0e7c2bd043ba  |
#|  dfdsf                                 |  sg-0c90e8a32f53c22ae  |
#|  launch-wizard-2                       |  sg-0d7f1b1be6599d5e7  |
#|  default                               |  sg-ed34be94           |
#+----------------------------------------+------------------------+
find_sg_name-id() {
	aws ec2 describe-security-groups --query "sort_by(SecurityGroups,&GroupName)[].[GroupName,GroupId]" --output table
        echo -n ": "
}
 
# 2. Details of each security group
get_sg_details() {
        echo -n "Group name: "
        read _GP_NM
 
	aws ec2 describe-security-groups --filters Name=group-name,Values=$_GP_NM Name=vpc-id,Values=$_VPC_ID --output text
        echo -n ": "
}
 
# 3. Associated instance output (with group ID specified)
find_ec2-instance() {
        echo -n "Group name: "
        read _GP_NM
 
        aws ec2 describe-instances | jq -r --arg _GP_NM "$_GP_NM" '.Reservations[].Instances[] | select (.SecurityGroups[].GroupName==$_GP_NM) | [.InstanceId, .Tags[].Value]'
        echo -n ": "
}
 
# 4. Associated instance output .csv file (with group ID specified) 
find_ec2-instance_output_csv() {
        echo -n "Group name: "
        read _GP_NM
 
        _DATE=`date "+%Y%m%d_%H%M%S"`
        _FILE_PATH='./output'
        _FILE_NAME='sg_'$_GP_NM-$_DATE.csv
        _FILE=$_FILE_PATH/$_FILE_NAME
 
        echo "InstanceId, Tags" > $_FILE
        aws ec2 describe-instances | jq -r --arg _GP_NM "$_GP_NM" '.Reservations[].Instances[] | select (.SecurityGroups[].GroupName==$_GP_NM) | [.InstanceId, .Tags[].Value] | @csv' >> $_FILE
        if [ $? -eq 0 ]; then
                echo "$_FILE was Created under the ./output direcotry." 
        fi
        echo -n ": "
}
 
 
# !Caution!
# 5. Associated instance output (Target: All)
find_all_ec2-instance_output_csv() {
	echo -n "Do you really want to run? (yes/no): "
	read _STOP_FLG
	if [ $_STOP_FLG = "yes" ] || [ $_STOP_FLG = "y" ];then
        	_DATE=`date "+%Y%m%d_%H%M%S"`
        	_FILE_PATH='./output'
        	_FILE_NAME='sg_all-'$_DATE.csv
        	_FILE=$_FILE_PATH/$_FILE_NAME
 
        	declare -a SECG=$(aws ec2 describe-security-groups | jq -r '.SecurityGroups[].GroupName')
        	for secg in ${SECG[@]}; do
                	echo "*** SecurityGroupName: $secg ***" >> $_FILE
                	echo "InstanceId, Tags" >> $_FILE
                	aws ec2 describe-instances | jq -r --arg _secg "${secg}" '.Reservations[].Instances[] | select(.SecurityGroups[].GroupName==$_secg) | [.InstanceId, .Tags[].Value] | @csv' >> $_FILE
                	echo "------------" >> $_FILE
        	done
        	if [ $? -eq 0 ]; then
                	echo "$_FILE was Created under the ./output direcotry." 
        	fi
        	echo -n ": "
	elif [ $_STOP_FLG = "no" ] || [ $_STOP_FLG = "n" ]; then
		main
	else
		find_all_ec2-instance_output_csv
	fi
}
 
main () {
 
        # preprocessing
        output_man
 
        # main_processing
        while true
        do
                read _MODE
                case "$_MODE" in
                   1)      find_sg_name-id ;;
                   2)      get_sg_details ;;
                   3)      find_ec2-instance ;;
                   4)      find_ec2-instance_output_csv ;;
                   5)      find_all_ec2-instance_output_csv ;;
                   6)      output_man ;;
                   q)      exit 0 ;;
                   *)      echo "It is not the correct number."; echo -n ": ";
                esac
        done
}
 
# Excuete Main process
main
