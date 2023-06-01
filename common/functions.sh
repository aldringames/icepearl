_msg() {
	echo -e "\e[1;32m>>\e[m $1"
}

_err() {
        echo -e "\e[1;31m>>\e[m $1"
}

_clone() {
	git clone --depth=1 -b $1 $2 $3
}
