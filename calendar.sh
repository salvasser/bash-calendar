#!/usr/bin/env bash

function DOC(){
    printf "Скрипт генерации календаря указанного года в формате html. Диапазон от 2000 до 2099 года.\nСинтаксис следующий:
    \n\t${0} -y <year> [-x8, -x16] [file.html]\n
Если файл не указан - файл по умолчанию: /tmp/<year>.html
Поддерживает вывод в восьмеричном при наличии флага [-x8] или шестнадцатеричном [-x16] форматах\n"
}

year=$(printf '%(%Y)T') ### по умолчанию текущий год
mode="dec" ### по умолчанию выводим в десятичном формате

### Обработка именованных параметров ###
(($# < 1)) && { DOC >&2; exit; }

while (($#>0)); do
    if [[ $1 == "-y" ]]; then
        shift
        year=$1
        ((year<2000)) && year=2025
        ((year>2099)) && year=2025
    elif [[ $1 == "-x8" ]]; then  # прикол-режим
        mode=oct
    elif [[ $1 == "-x16" ]]; then  # прикол-режим
        mode=hex
    else
        { DOC >&2; exit; }
    fi
    shift
done

### проверяем параметр с именем файла
if [[ (($# < 1)) || "${1##*.}" != "html" ]]; then
    outFile="/tmp/${year}.html"
else
    outFile=$1
fi

includeFile="./func.inc"
source $includeFile || { printf "%s\n" "$includeFile include error"; exit 1; }

CHECK_FILE $outFile
START_HTML $outFile

if [[ $mode == "oct" ]]; then
    outFormat="%s%#o%s\n"
elif [[ $mode == "hex" ]]; then
    outFormat="%s%#x%s\n"
else
    outFormat="%s%s%s\n"
fi
### вывод заголовка
printf $outFormat "<h1 style='text-align: left;'>" $year "</h1>" >> $outFile

for ((initMonth=1;initMonth<=12;initMonth++)); do

    ### прикол-режим для месяцев
    if [[ $mode == "oct" || $mode == "hex" ]]; then
        outMonth=$initMonth

    else
        outMonth=${monthARR[$initMonth]}
    fi

    ### тег для вывода 4 месяцев/таблиц в одну линию
    [[ $initMonth == 1 || $initMonth == 5 || $initMonth == 9 ]] && printf "\t\n%s\n" "<div style='white-space: nowrap; margin: 20px 0;'>" >> $outFile

    curMonth=$(printf "%02s" $initMonth) # добавляем ведущий 0 для месяцев меньше 10, чтобы date сработал корректно
    curDay="01"
    
    DT="${year}-${curMonth}-${curDay}"
    day=$(gdate -d "$DT" +%u)
    daysInMonth=$(DAYS_IN_MONTH $initMonth)
    curDay=${curDay#"0"} # удаляем ведущий 0

    ### вывод таблицы
    printf $outFormat "<table style='border: 1px solid rgb(255, 255, 255); width: 200px; display: inline-table; margin-right: 20px;'>
    <caption style='background-color:powderblue; font-weight:bold; font-size:1.2em;'>" $outMonth "</caption>" >> $outFile

    printf "%s\n" "$tableHead $tableStr" >> $outFile

    # выводим заголовок столбцов
    for ((j=1;j<8;j++)); do

    ### прикол-режим для дней недели
    if [[ $mode == "oct" || $mode == "hex" ]]; then
        outWeekDay=$(DEC2BIN $j)
    else
        outWeekDay=${daysArr[$j]}
    fi

        printf "%s %s %s\n" $culumnHead $outWeekDay $culumnHeadClose >> $outFile
    done
    printf "%s" "$tableStrClose $tableHeadClose" >> $outFile

    printf "$tableBody" >> $outFile
    # внешний цикл для строк-недель
    for ((i=0;i<6;i++)); do
        # внутренний цикл для дней недели
        printf "\n\t%s\n" $tableStr >> $outFile # начало строки
        for ((j=1;j<8;j++)); do
            out=$curDay
            [[ $i == 0 && $j < $day ]] && { out=""; printf "%s %s %s\n" "$cell" "$out" "$cellClose" >> $outFile; continue; } ### если есть прикол-режим, то пустые строки выводим отдельно
            printf $outFormat "$cell" "$out" "$cellClose" >> $outFile
            ((curDay == daysInMonth)) && break 2
            ((curDay++))
        done
        printf "\t%s" $tableStrClose >> $outFile # конец строки
    done

    ### конец таблицы
    printf "%s" "$tableBodyClose
    </table>" >> $outFile
    ### тег для вывода 4 месяцев/таблиц в одну линию
    [[ $initMonth == 4 || $initMonth == 8 || $initMonth == 12 ]] && printf "\t%s\n" "</div>" >> $outFile

done

printf "</body> </html>" >> $outFile