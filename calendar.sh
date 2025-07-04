#!/usr/bin/env bash

function DOC(){
    printf "%s\n%s\n\n%s\n\n%s\n%s\n" "Скрипт генерации календаря указанного года в формате html. Диапазон от 2000 до 2099 года." "Синтаксис следующий:" "${0} -y <year> [-x8, -x16] [file.html]" "Если файл не указан - файл по умолчанию: /tmp/<year>.html" "Поддерживает вывод в восьмеричном при наличии флага [-x8] или шестнадцатеричном [-x16] форматах"
}

year=$(printf '%(%Y)T') ### по умолчанию текущий год
mode="dec" ### по умолчанию выводим в десятичном формате

### Обработка именованных параметров ###
(($# < 1)) && { DOC >&2; exit; }

while (($#>0)); do
    if [[ $1 == "-y" ]]; then
        shift
        year=$1
        [[ -z $year ]] && { DOC >&2; exit; }
    elif [[ $((${#1} > 2)) && ${1:0:2} == "-y" ]]; then
        year=${1#-y}
    elif [[ $1 == "-x8" ]]; then  # прикол-режим
        mode=oct
    elif [[ $1 == "-x16" ]]; then  # прикол-режим
        mode=hex
    ### проверяем последний оставшийся параметр - здесь должно быть имя файла
    elif [[ (($# == 1)) || "${1##*.}" == "html" ]]; then
        outFile=$1
        break
    else
        { DOC >&2; exit; }
    fi
    shift
done

((year<2000)) && year=$(printf '%(%Y)T')
((year>2099)) && year=$(printf '%(%Y)T')

### проверяем название файла
if [[ $(($# < 1)) || "${outFile##*.}" != "html" ]]; then
    outFile="/tmp/${year}.html"
    printf "%s\n" "Некорректный формат файла или он отстуствует. Вывод осуществляется в $outFile"
fi

source "func.inc" || { printf "%s\n" "func.inc include error"; exit 1; }

CHECK_FILE "$outFile"
START_HTML "$outFile"

if [[ $mode == "oct" ]]; then
    outFormat="%s%#o%s\n"
elif [[ $mode == "hex" ]]; then
    outFormat="%s%#X%s\n"
else
    outFormat="%s%s%s\n"
fi

for ((initMonth=1;initMonth<=12;initMonth++)); do

    ### прикол-режим для месяцев
    if [[ $mode == "oct" || $mode == "hex" ]]; then
        outMonth=$initMonth

    else
        outMonth=${monthARR[$initMonth]}
    fi

    ### тег для вывода 4 месяцев/таблиц в одну линию, так же выводим заголовок
    [[ $initMonth == 1 ]] && printf $outFormat "<div style='white-space: nowrap; margin: 20px 0; text-align: center;'><h1>" "$year" "</h1>" >> "$outFile"
    [[ $initMonth == 5 || $initMonth == 9 ]] && printf "\t\n%s\n" "<div style='white-space: nowrap; margin: 20px 0; text-align: center;'>" >> "$outFile"

    curMonth=$(printf "%02s" $initMonth) # добавляем ведущий 0 для месяцев меньше 10, чтобы date сработал корректно
    curDay="01"
    
    DT="${year}-${curMonth}-${curDay}"
    day=$(date -d "$DT" +%u) ### это важно для того, чтобы определить с какого дня начинается месяц
    daysInMonth=$(DAYS_IN_MONTH "$DT")
    curDay=${curDay#"0"} # удаляем ведущий 0

    ### вывод таблицы
    printf $outFormat "<table style='border: 1px solid rgb(255, 255, 255); width: 200px; display: inline-table; margin-right: 20px;'>
    <caption style='background-color:powderblue; font-weight:bold; font-size:1.2em;'>" "$outMonth" "</caption>" >> "$outFile"

    printf "%s\n" "$tableHead $tableStr" >> "$outFile"

    # выводим заголовок столбцов
    for ((j=1;j<8;j++)); do

    ### прикол-режим для дней недели
    if [[ $mode == "oct" || $mode == "hex" ]]; then
        outWeekDay=$(DEC2BIN $j)
    else
        outWeekDay=${daysArr[$j]}
    fi

        printf "%s %s %s\n" $culumnHead "$outWeekDay" $culumnHeadClose >> "$outFile"
    done
    printf "%s" "$tableStrClose $tableHeadClose" >> "$outFile"

    printf "$tableBody" >> "$outFile"
    # внешний цикл для строк-недель
    for ((i=0;i<6;i++)); do
        # внутренний цикл для дней недели
        printf "\n\t%s\n" "$tableStr" >> "$outFile" # начало строки
        for ((j=1;j<8;j++)); do
            out=$curDay
            [[ $i == 0 && $((j < day)) ]] && { out=""; printf "%s %s %s\n" "$cell" "$out" "$cellClose" >> "$outFile"; continue; } ### если есть прикол-режим, то пустые строки выводим отдельно
            printf $outFormat "$cell" "$out" "$cellClose" >> "$outFile"
            ((curDay == daysInMonth)) && break 2
            ((curDay++))
        done
        printf "\t%s" "$tableStrClose" >> "$outFile" # конец строки
    done

    ### конец таблицы
    printf "%s" "$tableBodyClose
    </table>" >> "$outFile"
    ### тег для вывода 4 месяцев/таблиц в одну линию
    [[ $initMonth == 4 || $initMonth == 8 || $initMonth == 12 ]] && printf "\t%s\n" "</div>" >> "$outFile"

done

printf "</body> </html>" >> "$outFile"
