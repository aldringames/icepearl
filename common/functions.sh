_msg() {
	echo -e "\e[1;32m>>\e[m $@"
}

_err() {
        echo -e "\e[1;31m>>\e[m $@"
}

_indent() {                                                                                     sed -u "s/^/"$(echo -e "\e[1;32m>>\e[m")" /"
}

_clone() {
        git clone -b $1 $2 $3 | _indent > /dev/null
}

_fetch() {
	wget -q -O- $1 | tar -Jxvf- --strip-components=1 -C $2 | _indent > /dev/null
}

_make() {
	make -j4 $@ | _indent > /dev/null
}

_make_install() {
	make DESTDIR=$@ install | _indent > /dev/null
}
