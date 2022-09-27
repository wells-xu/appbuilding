#/bin/bash
export DIR_API_DEFAULT=$(cd $(dirname $0); pwd)/api
[ ! -d $DIR_API_DEFAULT ] && DIR_API_DEFAULT=~/.local/api
echo "----------------------$0 DIR_API_DEFAULT = $DIR_API_DEFAULT build.sh----------------------"

source $DIR_API_DEFAULT/use.sh

linux_to_win_path() {
	say_is_not_null $1
	local tmp_path=${1:1}
	tmp_path1=$(echo $tmp_path | sed 's/\//:\//')
	tmp_path2=$(echo $tmp_path1 | sed 's/\//\\/g')
	echo $tmp_path2
}
test_linux_to_win_path() {
	local test_path=$(linux_to_win_path /c/Users/wells/source/repos/github.com/wells-xu/test_curl/third/tmp/c-ares/msvc/cares)
	echo $test_path
}

build_cares() {
	log_msg "c-ares building started..."
	local dir_root=$(pwd)
	log_msg "root path= $dir_root"
	#step 0
	log_msg "Step0: clear old compiled files first..."
	if is_dir_exist $dir_root/c-ares/msvc; then
		do_or_die rm -rv $dir_root/c-ares/msvc
	fi
	log_ok "Step0: done"
	
	#step 1
	if [ ! -d "./c-ares" ]; then
		log_msg "Step1: fetching c-ares from github now..."
		do_or_die git clone https://github.com/c-ares/c-ares.git
	else
		log_msg "Step1: c-ares already exist."
	fi
	log_ok "Step1: done"
	
	#step 2
	log_msg "Step2: doing default configuration..."
	
	cd c-ares && ./buildconf.bat
	log_msg "Step2: done."
	
	#step3
	log_msg "Step3: calling the MSVC command line tool..."
	log_msg "Step3: You MUST input the command: [nmake -f Makefile.msvc]"
	if [ $1 == "x64" ]; then
		do_or_die $DIR_BIN/../comm/msvc_x64_command_line.bat
	else
		do_or_die $DIR_BIN/../comm/msvc_x86_command_line.bat
	fi
		
	#$COMSPEC /k "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" cl.exe /?
	log_ok "Step3: building c-ares done."
	
	log_msg "output path is: $dir_root/c-ares/msvc/cares"	
	ls -la $dir_root/c-ares/msvc/cares
		
	log_msg "Step4: deploy inlucde files and lib files which used by libcurl"
	log_msg "entering $dir_root/c-ares"
	say_is_dir_exist ./include
	do_or_die mkdir -p $dir_root/c-ares/msvc/cares/include
	say_is_dir_exist $dir_root/c-ares/msvc/cares/include
	if is_dir_not_exist ./msvc/cares/include/cares; then
		do_or_die cp -rv ./include ./msvc/cares/include/
		do_or_die mv -v ./msvc/cares/include/include ./msvc/cares/include/cares
	fi
	if is_dir_not_exist ./msvc/cares/lib; then
		do_or_die mkdir -p ./msvc/cares/lib
	fi
	
	if is_dir_exist ./msvc/cares/dll-debug; then
		cp -v ./msvc/cares/dll-debug/caresd.lib ./msvc/cares/lib
		cp -v ./msvc/cares/dll-debug/caresd.dll ./msvc/cares/lib
	fi
	if is_dir_exist ./msvc/cares/dll-release; then
		cp -v ./msvc/cares/dll-debug/cares.lib ./msvc/cares/lib
		cp -v ./msvc/cares/dll-debug/cares.dll ./msvc/cares/lib
	fi
	if is_dir_exist ./msvc/cares/lib-debug; then
		cp -v ./msvc/cares/dll-debug/libcaresd.lib ./msvc/cares/lib
	fi
	if is_dir_exist ./msvc/cares/lib-release; then
		cp -v ./msvc/cares/dll-debug/libcares.lib ./msvc/cares/lib
	fi
	log_ok "Step4: done"
	
	cd $dir_root
}

build_libcurl() {
	log_msg "libcurl building started..."
	local dir_root=$(pwd)
	log_msg "root path= $dir_root"
	
	#step 0
	log_msg "Step0: clear old compiled files first..."
	if is_dir_exist $dir_root/curl/builds; then
		do_or_die rm -rv $dir_root/curl/builds
	fi
	log_ok "Step0: done"
	
	#step 1
	if [ ! -d "./curl" ]; then
		log_msg "Step1: fetching c-ares from github now..."
		do_or_die git clone https://github.com/curl/curl.git
	else
		log_msg "Step1: curl already exist."
	fi
	log_ok "Step1: done"
	
	#step 2
	log_msg "Step2: doing default configuration..."
	
	log_msg "entering $dir_root/curl"
	cd $dir_root/curl && ./buildconf.bat
	log_ok "Step2: done."
	
	#step3
	log_msg "entering $dir_root/curl/winbuild..."
	cd $dir_root/curl/winbuild
	log_msg "Step3: calling the MSVC command line tool..."
	local test_path=$(linux_to_win_path /c/Users/wells/source/repos/github.com/wells-xu/test_curl/third/tmp/c-ares/msvc/cares)
	log_ok $test_path
	local win_root=$(linux_to_win_path $dir_root/c-ares/msvc/cares)
	log_msg "Step3: You MUST input the command: [nmake /f Makefile.vc mode=static WITH_CARES=static ENABLE_SCHANNEL=yes DEBUG=yes MACHINE=$1 WITH_DEVEL=$win_root]"
	if [ $1 == "x64" ]; then
		do_or_die $DIR_BIN/../comm/msvc_x64_command_line.bat
	else
		do_or_die $DIR_BIN/../comm/msvc_x86_command_line.bat
	fi
	#$COMSPEC /k "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" cl.exe /?
	log_ok "Step3: building libcurl done."
	
	log_msg "output path is: $dir_root/curl/builds"
	ls -la $dir_root/curl/builds
	cd $dir_root
}

main() {
	log_msg "building libcurl starting..."
	local machine_flag=$1
    if is_null $machine_flag;then
		machine_flag=x86
    fi
	if [ $machine_flag != "x86" -a $machine_flag != "x64" ]; then
		echo "MUST BUILD WITH MACHINE TYPE x86 or x64"
		exit 1
	fi
	log_msg "Your building mode is: $machine_flag"

	build_cares $machine_flag
	build_libcurl $machine_flag
	
	log_msg "All done quit with any input"
	read
}

main "$@"
