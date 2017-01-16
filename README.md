# hadoop installer

---

## files in this installer package:

- hadoop-2.7.1.tar.gz
- install.sh
- readme.html

---

## usage:

1. extract the package to get the files listed above

2. change directory to the path that you extract the package to

3. run `sudo ./install.sh` command to run the installer

	**if you are not running ubuntu, goto install.sh to modify the `INSTALL_CMDS` to fit your system.**

4. if no `[ERRO]` notices in the output, it means hadoop-2.7.1 has been successfully installed

---

## operations of the program:

- A user named "hadoop" is added to your computer

- User "hadoop" has been authorized with sudo

- The hadoop programs are installed to /usr/local/hadoop

- Add "/usr/local/hadoop/bin" and "/usr/local/hadoop/sbin" to PATH environmental variable (which means all hadoop commands can be runned through command line)

- "vim" "build-essential" "openssh-server" "rsync" "openjdk-8-jre" "openjdk-8-jdk" has been installed to your system which is required by hadoop

- hadoop has been configured to Pseudo-Distributed Operation

---

## what you should do next:

1. use passwd command to set a password for hadoop to login

	sudo passwd hadoop

2. login with hadoop

	su hadoop

3. generate ssh-key for hadoop

	ssh-keygen

4. copy ssh-key to localhost and 0.0.0.0

	ssh-copy-id localhost

	ssh-copy-id 0.0.0.0

5. format hadoop namenode

	hadoop namenode -format

6. start hadoop

	start-all.sh

7. test your hadoop

	see [namenode information page](http://localhost:50070) to get more information about your namenode.

