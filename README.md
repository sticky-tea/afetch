# afetch
![afetch](https://i.imgur.com/9bHOhsM.png)  
A command-line system information tool written in x86 assembly language. Linux-only because of linux syscalls
## How to install
### Required dependencies
* lsb_release  
Also *[fasm](https://flatassembler.net/)* to compile and *make* to make (optional)
### Installing
```bash
$ make && sudo make install
```
or
```bash
$ fasm afetch.asm && chmod +x afetch && ./afetch
```
