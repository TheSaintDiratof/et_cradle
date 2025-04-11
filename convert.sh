#!/usr/bin/env bash
# convert.sh txt mode output_directory
# Функция для обработки содержимого между тегами
get_content() {
    local tag="$1"
    local line="$2"
    echo "$line" | sed -n "s/.*($tag)\(.*\)(\/$tag).*/\1/p"
}

function join_by {
    local d=${1-} f=${2-}
    if shift 2; then
        printf %s "$f" "${@/#/$d}"
    fi
}

#/:
# pages/.......
# styles/......
# images/......
mode=$2
color=$3
OUTPUT=$(realpath $4)
ROOT=$(realpath $5)
#readarray -d "/" CWD <<< $(dirname $(realpath $1))
#unset CWD[-1]
#readarray -d "/" ROOT <<< $(realpath $5)
#echo ${ROOT[@]}
#for i in ${ROOT[@]}; do
#  ROOT_Str=$(echo $ROOT_Str$i)
#done
#for i in ${CWD[@]}; do
#  CWD_Str=$(echo $CWD_Str$i)
#done
if [[ $mode == "desktop" ]]; then
  style="desktop"
  alt_mode="mobile"
  alt_mode_name="Мобильная версия"
elif [[ $mode == "plain-text" ]]; then
  style="plain-text"
  alt_mode="desktop"
  alt_mode_name="Настольная версия"
else
  style="mobile"
  alt_mode="desktop"
  alt_mode_name="Настольная версия"
fi
if [[ $color == "dark" ]]; then
  alt_color="light"
  alt_color_name="Светлая тема"
else
  alt_color="dark"
  alt_color_name="Тёмная тема"
fi
input_file="$(realpath $1)"
output_file="$(echo $input_file | sed -e "s|$ROOT|$OUTPUT|" -e "s|pages|$mode/$color|" -e "s|txt|html|" -e "s|страница|index|")"
#CWD_Str="$(echo $CWD_Str | sed -e "s|$ROOT||" -e "s|pages|images|")"
CWD="$(dirname $(realpath $1))"
mkdir -p "$(dirname $output_file)" && touch "$output_file"
RCWF="$(echo $input_file | sed -e "s|$ROOT/pages||" -e "s|страница|index|" -e "s|txt|html|")"

> "$output_file"
block_ids=()
# Обработка файла
while IFS= read -r line; do
    if [[ $line == *"(заголовок)"* ]]; then
        title=$(get_content "заголовок" "$line")
    elif [[ $line == *"(блок "* ]]; then
        block_id=$(echo "$line" | sed 's/.*(блок \([^)]*\)).*/\1/')
        block_ids=$(echo "$block_ids $block_id")
    fi
done < "$input_file"
while IFS= read -r line; do
    if [[ $line == *"(корень)"* ]]; then
        echo "<html>" >> "$output_file"
        cat << EOF >> "$output_file"

<head>
<meta charset="UTF-8">
<title>$title</title>
<link rel="stylesheet" type="text/css" href="/styles/$mode$color.css">
EOF
        echo '<div class="headnav">' >> "$output_file"
        if [[ $mode != "plain-text" ]]; then
            echo '<img src="/logo.png" alt="Логотип ЛЭТИ" width="100" height="100">' >> "$output_file"
        fi
        cat << EOF >> "$output_file"
<a href="/$mode/$color/index.html" class="navigation">Главная</a>
<a href="../index.html" class="navigation">Назад</a>
<a href="/$mode/$alt_color$RCWF" class="navigation">$alt_color_name</a>
<a href="/$alt_mode/$color$RCWF" class="navigation">$alt_mode_name</a>
<a href="/plain-text/$color$RCWF" class="navigation">Текстовая версия</a>
</div>
EOF
        if [[ $2 == "desktop" ]]; then

            echo '<div class="sidenav">' >> "$output_file"
            echo '<ul>' >> "$output_file"
            for i in $block_ids; do
              echo "<li><a href=\"#$i\" class=\"navigation\">$i</a></li>" >> "$output_file"
            done
            echo '<ul>' >> "$output_file"
            echo "</div>" >> "$output_file"
        fi

        echo "</head>" >> "$output_file"
        echo "<body>" >> "$output_file"
    elif [[ $line == *"(/корень)"* ]]; then

        echo "</body>" >> "$output_file"
        echo "</html>" >> "$output_file"
    elif [[ $line == *"(заголовок)"* ]]; then
      continue
    elif [[ $line == *"(блок "* ]]; then
        block_id=$(echo "$line" | sed 's/.*(блок \([^)]*\)).*/\1/')
        block_ids=$(echo "$block_ids $block_id")
        echo "<div class=\"content\" id=\"$block_id\">" >> "$output_file"
    elif [[ $line == *"(/блок)"* ]]; then
        echo "</div>" >> "$output_file"
    elif [[ $line == *"(параграф)"* ]]; then
        para_content=$(echo "$line" | sed -e 's/(параграф)//' -e 's/(\/параграф)/<\/p>/' )
        para_content=$(echo "$para_content" | sed -e 's/(ссылка на="\([^"]*\)")/<a href="\1">/g' -e 's/(\/ссылка)/<\/a>/g')
        echo "<p class=\"plain-text\">$para_content" >> "$output_file"
      elif [[ $line = *"(/параграф)"* ]]; then
        echo "$line" | sed -e 's/(\/параграф)/<\/p>/' >> "$output_file"
    elif [[ $line == *"(ссылка "?*")"* ]]; then
        echo "$line" | sed -e "s/(ссылка на=\"\([^\"]*\)\")/<a href=\"\/$mode\/$color\1\" class=\"link\">/g" -e 's/(\/ссылка)/<\/a>/g' >> "$output_file"
    elif [[ $line == *"(изображение"?*")"* ]]; then
      alt=$(echo "$line" | sed 's/.*(изображение \([^)]*\)).*/\1/')
      if [[ $mode != "plain-text" ]]; then
          img_src=$(echo $line | sed -n 's|.*)\([^)]*\)(.*|\1|p')
          if [[ "${img_src:0:1}" == "/" ]]; then
              img_src="/images$img_src"
          else
              img_src=$(realpath $CWD/$img_src)
              img_src=$(echo $img_src | sed "s|$ROOT/pages|/images|")
          fi
          echo "<img src=\"$img_src\" alt=\"$alt\" class=\"image\">" >> "$output_file"
      else
          echo "<p class=\"plain-text-img\">$alt</p>" >> "$output_file"
      fi
    else
        echo "$line" >> "$output_file"
    fi
done < "$input_file"

echo "Файл успешно преобразован: $output_file"
