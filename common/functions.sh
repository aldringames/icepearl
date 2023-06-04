_msg() {
	echo -e "\e[1;32m>>\e[m $@"
}

_err() {
        echo -e "\e[1;31m>>\e[m $@"
}

_clone() {
	git clone --depth=1 -b $1 $2 $3 > /dev/null
}

_make() {
	make -j4 $@ > /dev/null
}

_make_install() {
	make DESTDIR=$@ install > /dev/null
}
