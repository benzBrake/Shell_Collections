# fail2ban.sh
Install & configure fail2ban automatic

```shell
sh -c "$(wget --no-check-certificate https://raw.githubusercontent.com/Char1sma/Shell_Collections/master/fail2ban/fail2ban.sh -O -)" -c "install"
```

## Notice for zsh user
please run `echo export PATH=~/bin:$PATH>> .zshrc`

## Show Login Error Logs

```shell
fb.sh showlog
```

## Uninstall

```shell
fb.sh uninstall
```

## Credits

Thanks to Yaroslav O. Halchenko <debian@onerussian.com> for fail2ban configure files