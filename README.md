# afetch
![afetch](https://i.imgur.com/d2E2zRc.png)  
A command-line system information tool written in x86 assembly language
## How to install
### Required dependencies
* lsb_release
* fasm
### Installing
```bash
$ make && sudo make install
```
or
```bash
$ fasm afetch.asm && ./afetch
```
Maybe you will need to do
```bash
$ chmod +x afetch
```
