#!/bin/zsh
FILE="list_instances.txt"
FILE_FINAL="final.txt"
FILE_PLATFORM="platform_result.txt"
FILE_FOLDERS_LIST="folders_list.txt"

echo -n "Введите cloud-id: "
read cloud_id
yc resource-manager folder list --cloud-id $cloud_id --format json | jq ".[].id" -r &> $FILE_FOLDERS_LIST

files=($FILE $FILE_FINAL $FILE_PLATFORM $FILE_FOLDERS_LIST)

for file in $files
do
touch $file
done


while read folders
do
    yc compute instance list --folder-id=$folders | awk '{print $2}' | grep "^[a-z0-9]\{20\}$" &>> $FILE
done < $FILE_FOLDERS_LIST


for line in $(cat $FILE); do
    echo "Instance ID: $line" &>> $FILE_FINAL
    yc compute instance get --id=$line | grep "platform_id" &>> $FILE_FINAL
    yc compute instance get --id=$line | grep -A2 "resources:" &>> $FILE_FINAL
    echo "----------------------------------"  &>> $FILE_FINAL
done

echo "Количество ВМ в облаке клиента на платформе Intel Cascade Lake: $(cat $FILE_FINAL | grep "standard-v2" | wc -l)" &>> $FILE_PLATFORM
echo "Количество ВМ в облаке клиента на платформе Intel Ice Lake: $(cat $FILE_FINAL | grep "standard-v3" | wc -l)" &>> $FILE_PLATFORM

# Creating zip-archive and deleting old files
for file in $files
do
zip resources.zip $file
rm $file
done
