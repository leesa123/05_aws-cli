#!/bin/bash

# 0. Output Manual
output_man() {
        echo ""
        echo "----------------------------------------------------------------------------------"
        echo "|                               Ec2ManagementTool_v1                             |"
        echo "+--------------------------------------------------------------------------------+"
        echo "| *SELECT MODE*                                                                  |"
        echo "|<1> All EC2-instance                                                            |"
        echo "|<2> All EC2-instance output .csv file                                           |"
        echo "|<3> Associated security groups output                                           |"
        echo "|<6> Manual                                                                      |"
        echo "|<q> exit                                                                        |"
        echo "+--------------------------------------------------------------------------------+"
        echo -n ": "
}
 
# 1. Get the entire list
#
# ex)
#------------------------------------------------------------------------------------------------------------------------------------------------------
#|                                                                  DescribeInstances                                                                 |
#+---------------------------------------+----------------------+------------+---------------+-----------------+----+----+----------------------------+
#|  Tag[?Key=Name]                       |  InsId               |  InsType   |  PriIp        |  ElaIp          |Cpu |Thr |  Subnet                    |
#+---------------------------------------+----------------------+------------+---------------+-----------------+----+----+----------------------------+
#|  MLT-WEB-ATK01                        |  i-0054cfb2156ab0d9d |  t3.medium |  10.60.16.36  |  None           |  1 |  2 |  subnet-0ef7a7be14147e2f8  |
#|  DRP-WEB-ATK01                        |  i-04adf65dafb1a2e62 |  t3.small  |  10.60.16.68  |  52.196.123.159 |  1 |  2 |  subnet-0cb333a2470b69705  |
#|  ........                             |  ...                 |  ...       |  ...          |  ...            | ...| ...|  ...                       |
#|  ........                             |  ...                 |  ...       |  ...          |  ...            | ...| ...|  ...                       |
#+---------------------------------------+----------------------+------------+---------------+-----------------+----+----+----------------------------+
find_all-instances() {
        aws ec2 describe-instances --query  'Reservations[].Instances[].[Tags[?Key==`Name`].Value|[0],InstanceId,InstanceType,PrivateIpAddress,PublicIpAddress,CpuOptions.CoreCount,CpuOptions.ThreadsPerCore,SubnetId]' --output table
        echo -n ": "
}
 
# 2. Details of each security group
find_all-instances_output_csv() {
        _DATE=`date "+%Y%m%d_%H%M%S"`
        _FILE_PATH='./output'
        _FILE_NAME='all_ec2'-$_DATE.csv
        _FILE=$_FILE_PATH/$_FILE_NAME

	# Header
	echo "Name, InstanceId, InstanceType, CoreCount,ThreadsPerCore, AvailabilityZone, EbsOptimized, VpcId, VirtualizationType, PublicDnsName, PublicIpAddress, PrivateDnsName, PrivateIpAddress, KeyName" >> $_FILE

	# Content
	aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | [( .Tags[]| select(.Key == "Name") | .Value ),.InstanceId,.InstanceType,.CpuOptions.CoreCount,.CpuOptions.ThreadsPerCore,.Placement.AvailabilityZone,.EbsOptimized,.VpcId,.VirtualizationType,.PublicDnsName,.PublicIpAddress,.PrivateDnsName,.PrivateIpAddress,.KeyName] | @csv' >> $_FILE
	if [ $? -eq 0 ]; then
        	echo "$_FILE was Created under the ./output direcotry."
        fi
        echo -n ": "
}

# 3. Associated security groups output
find_all-Associated-security-groups() {
        echo -n "Instance name: "
        read _INS_NM

	aws ec2 describe-instances --filter "Name=tag:Name, Values=${_INS_NM}" --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value|[0],SecurityGroups]' --output text
	echo -n ": "
}
 
main () {
 
        # preprocessing
        output_man
 
        # main_processing
        while true
        do
                read _MODE
                case "$_MODE" in
                   1)      find_all-instances ;;
                   2)      find_all-instances_output_csv ;;
                   3)      find_all-Associated-security-groups ;;
                   6)      output_man ;;
                   q)      exit 0 ;;
                   *)      echo "It is not the correct number."; echo -n ": ";
                esac
        done
}
 
# Excuete Main process
main
