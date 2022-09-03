#!/bin/bash

# duplication check
cat client |awk -F',' '{print $1}' |sort |uniq -d | grep -P "\D" && exit 1
cat member |awk -F',' '{print $1}' |sort |uniq -d | grep -P "\D" && exit 2

# telegram bot id
BOT_ID="XXXX:XXXX"

DIR=`dirname $0`

cd ${DIR}

# get google calender schedule
python3 get_events.py | sed -e 's:<html-blob>::g' -e 's:</html-blob>::g' -e "s:<br>:\n:g" > schedule.txt

# make text
sed -e "s/DATE/`date +%Y-%m-%d --date tomorrow`/" reverse.sed > make_reverse.sed
sed -n "/`date +%Y-%m-%d --date tomorrow`/,/^$/p" schedule.txt  | sed -f make_reverse.sed | sed -e "s:`date +%Y-%m-%d --date tomorrow`:`date +%m/%d --date tomorrow`:" -e "s/~.*//" > make.txt

cp -f make.txt make2.txt
test -f make.txt.`date +%Y%m%d` && diff make.txt make.txt.`date +%Y%m%d` && exit 1
test -f make.txt.`date +%Y%m%d` && diff make.txt make.txt.`date +%Y%m%d` |grep '<' |sed -e 's/< //g' > make2.txt

# make file
test -d ./FILE || mkdir ./FILE

# get client
python3 spreadsheet_client.py |sed -e 's/],/\n/g' -e 's/]//g' -e 's/\[//g' -e "s/'//g" -e "s/ //g" > client

# get member
python3 spreadsheet_member.py |sed -e 's/],/\n/g' -e 's/]//g' -e 's/\[//g' -e "s/'//g" -e "s/ //g" > member

while read line
do
echo $line  |grep -q Title && ID=`grep "\`echo $line |awk -F'　' '{print $1}' |sed -e "s/Title://"\`" member |awk -F',' '{print $2}'`
echo $line  |grep -q Title && MEM=`grep "\`echo $line |awk -F'　' '{print $1}' |sed -e "s/Title://"\`" member |awk -F',' '{print $1}'`
echo $line  |grep -q Title && FILE_NAME=`echo $line |sed -e "s/Title://" -e "s/　/_/g"`
echo $line  |grep -q Title && grep "`echo $line |awk -F'　' '{print $2}'`" client >> ./FILE/${ID}_${FILE_NAME}
echo $line  |grep -q Title || echo $line >> ./FILE/${ID}_${FILE_NAME}

done < make2.txt


mkdir DSC

# post telegram
for i in `ls -tr ./FILE |grep -v "キャンセル"`
do

ID=`echo $i |awk -F'_' '{print $1}'`
MEM=`echo $i |awk -F'_' '{print $2}'`

DATE=`tail -n1 ./FILE/$i`
CLI=`head -n1 ./FILE/$i|awk -F',' '{print $2" 様  "$3"  "$4"\\\\n"$5}'`

TXT=`cat ./FILE/$i | sed -e '1d' -e '$d' -e 's/$/ \\\\n/'`

echo "
$DATE \\n
$TXT \\n
$CLI \\n
\\n
\\n" >> ./DSC/${ID}_${MEM}

done

for i in `ls ./DSC`
do

ID=`echo $i |awk -F'_' '{print $1}'`
MEM=`echo $i |awk -F'_' '{print $2}'`

TXT=`cat ./DSC/$i`

DSC="
$MEM さん \\n
前日確認です。 \\n
\\n
$TXT
ご確認よろしくお願い致します。
"

curl -s  -H 'Accept: application/json' -H "Content-type: application/json" -X POST "https://api.telegram.org/bot${BOT_ID}/sendMessage?chat_id=${ID}" -k -d @- <<EOF
{
    "text": "${DSC}"
}
EOF

echo ""

done

rm -f ./FILE/*
rm -f ./DSC/*

cp -f make.txt make.txt.`date +%Y%m%d`

test -f make.txt.`date +%Y%m%d -d'1 day ago'` && rm -f make.txt.`date +%Y%m%d -d'1 day ago'`

rm -f ./client
rm -f ./member

exit 0
