### теги
cell='<td style="border: 1px solid rgb(255, 255, 255);">'
cellClose="</td>"
tableStr="<tr>"
tableStrClose="</tr>"
culumnHead="<th style='text-align: left;'>"
culumnHeadClose="</th>"
horizontalTable="float: left; margin-right: 20px;"
tableHead="<thead>"
tableHeadClose="</thead>"
tableBody="<tbody>"
tableBodyClose="</tbody>"

### ассоциативные массивы
declare -A daysArr=([1]="Пн" [2]="Вт" [3]="Ср" [4]="Чт" [5]="Пт" [6]="Сб" [7]="Вс")
declare -A monthARR=([1]="Январь" [2]="Февраль" [3]="Март" [4]="Апрель" [5]="Май" [6]="Июнь" [7]="Июль" [8]="Август" [9]="Сентябрь" [10]="Октябрь" [11]="Ноябрь" [12]="Декабрь")

### функция для работы с файлами
function CHECK_FILE(){
    local FILE=$1
    [[ -f "$FILE" ]] && rm "$FILE"
    touch "$FILE"
}

### html начало файла
function START_HTML(){
    printf '<!DOCTYPE html><html lang="ru">
    <head>
    <meta charset="UTF-8">
    <title>calendar</title>
    </head>
    <body>' >> "$1"
}
###

function DAYS_IN_MONTH() {
    year=$(date -d "$1" +%Y)
    month=$(date -d "$1" +%m)
    month=${month#"0"} # удаляем ведущий 0
    ##### проверка на високосный год #####
    [[ ( $((year % 4)) == 0 && $((year % 100)) != 0 ) || ( $((year % 100)) == 0 && $((year % 400)) == 0 ) ]] && vis=1
    ##### учитываем февраль #####
    ((month == 2)) && febr=$((2-vis))
    ############ первая половина вычисляет для месяцев 1-7 ############ вторая вычисляет для месяцев 8-12 #
    daysInMonth=$(( (month % 2 + 30) - (month / 8) * (month % 2 + 30) + (month / 8) * (31 - month % 2) - febr ))
    ### ((month / 8)) даст _0_ для месяцев 1-7 и _1_ для месяцев 8-12;
    ### для месяцев 1-7 работает только выражение ((month % 2 + 30)). остальное только для того, чтобы получить 0 для месяцев 8-12
    ### для месяцев 8-12 работает только выражение ((31 - month % 2)). остальное только для того, чтобы получить 0 для месяцев 1-7
    printf "%s" $daysInMonth
}

function REV(){
    REV=${1:-""}
    CHAR_ELEM=${#REV}
    while [[ $CHAR_ELEM -ge 0 ]]; do
        printf "%s" "${REV:$CHAR_ELEM:1}"
        ((CHAR_ELEM--))
    done
}

function DEC2BIN(){ 
    num=$1
    op=2;
    quo=$(( num / op)); rem=$(( num % op));
    remarray=();
    remarray+=("$rem"); 
        until [[ $quo -eq 0 ]]; do
            num=$quo; quo=$(( num / op));
            rem=$(( num % op)); remarray+="$rem";
        done
    binary=$(REV "${remarray[@]}");
    printf "%03i\n" "$binary";
}
