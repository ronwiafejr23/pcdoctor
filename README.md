# pcdoctor 🩺

A  health checkup for Linux computers.

Linux tells you what's wrong, just not in a way most people understand. pcdoctor checks your computer, explains each problem in plain English, gives you the exact command that fixes it, and can fix things for you if you say yes

## What it checks

| Check | What it looks for |
|---|---|
| Disk space | Drives that are almost full |
| Memory (RAM) | High memory use and which programs are using it |
| CPU | Overloaded processor and which programs are using it |
| Battery | Battery health compared to when it was new |
| Background services | Services that crashed or failed to start |
| Updates | Waiting updates and restarts that are needed |
| Security | Firewall off, root SSH login, open ports |
| Junk files | Trash, caches, old installers and logs over 500 MB |

At the end you get a **health score out of 100**.

## How to use it

```bash
git clone https://github.com/ronwiafejr23/pcdoctor.git
cd pcdoctor
chmod +x pcdoctor.sh
./pcdoctor.sh
```

| Command | What it does |
|---|---|
| `./pcdoctor.sh` | Run the checkup |
| `sudo ./pcdoctor.sh` | Include the firewall check |
| `./pcdoctor.sh --fix` | Offer to fix problems, asking y/n before each one |
| `./pcdoctor.sh --report` | Save the results to a text file |
| `./pcdoctor.sh --help` | Show all options |

## Fix mode is safe

`--fix` never changes anything without asking. It shows you the exact command first, and you type `y` to run it or press Enter to skip.

## Requirements

- Any Linux system (Ubuntu, Debian, Fedora, WSL)
- Bash, which comes with Linux. Nothing to install.

## Built with

Bash, `/proc` and `/sys` (where Linux exposes system info), `df`, `ps`, `ss`, `systemctl`, and `journalctl`.

## Author

Ron Wiafe Jr. · [LinkedIn](https://linkedin.com/in/ron-wiafe-jr)
# pcdoctor 🩺

A plain-English health checkup for Linux computers.

Linux tells you what's wrong, just not in a way most people understand. pcdoctor checks your computer, explains each problem in plain English, gives you the exact command that fixes it, and can fix things for you if you say yes.

![pcdoctor output](screenshot.png)

## What it checks

| Check | What it looks for |
|---|---|
| Disk space | Drives that are almost full |
| Memory (RAM) | High memory use and which programs are using it |
| CPU | Overloaded processor and which programs are using it |
| Battery | Battery health compared to when it was new |
| Background services | Services that crashed or failed to start |
| Updates | Waiting updates and restarts that are needed |
| Security | Firewall off, root SSH login, open ports |
| Junk files | Trash, caches, old installers and logs over 500 MB |

At the end you get a **health score out of 100**.

## How to use it

```bash
git clone https://github.com/ronwiafejr23/pcdoctor.git
cd pcdoctor
chmod +x pcdoctor.sh
./pcdoctor.sh
```

| Command | What it does |
|---|---|
| `./pcdoctor.sh` | Run the checkup |
| `sudo ./pcdoctor.sh` | Include the firewall check |
| `./pcdoctor.sh --fix` | Offer to fix problems, asking y/n before each one |
| `./pcdoctor.sh --report` | Save the results to a text file |
| `./pcdoctor.sh --help` | Show all options |

## Fix mode is safe

`--fix` never changes anything without asking. It shows you the exact command first, and you type `y` to run it or press Enter to skip.

## Requirements

- Any Linux system (Ubuntu, Debian, Fedora, WSL)
- Bash, which comes with Linux. Nothing to install.

## Built with

Bash, `/proc` and `/sys` (where Linux exposes system info), `df`, `ps`, `ss`, `systemctl`, and `journalctl`.

## Author

Ron Wiafe Jr. · [LinkedIn](https://linkedin.com/in/ron-wiafe-jr)# pcdoctor 🩺

A plain-English health checkup for Linux computers.

Linux tells you what's wrong, just not in a way most people understand. pcdoctor checks your computer, explains each problem in plain English, gives you the exact command that fixes it, and can fix things for you if you say yes.

![pcdoctor output](screenshot.png)

## What it checks

| Check | What it looks for |
|---|---|
| Disk space | Drives that are almost full |
| Memory (RAM) | High memory use and which programs are using it |
| CPU | Overloaded processor and which programs are using it |
| Battery | Battery health compared to when it was new |
| Background services | Services that crashed or failed to start |
| Updates | Waiting updates and restarts that are needed |
| Security | Firewall off, root SSH login, open ports |
| Junk files | Trash, caches, old installers and logs over 500 MB |

At the end you get a **health score out of 100**.

## How to use it

```bash
git clone https://github.com/ronwiafejr23/pcdoctor.git
cd pcdoctor
chmod +x pcdoctor.sh
./pcdoctor.sh
```

| Command | What it does |
|---|---|
| `./pcdoctor.sh` | Run the checkup |
| `sudo ./pcdoctor.sh` | Include the firewall check |
| `./pcdoctor.sh --fix` | Offer to fix problems, asking y/n before each one |
| `./pcdoctor.sh --report` | Save the results to a text file |
| `./pcdoctor.sh --help` | Show all options |

## Fix mode is safe

`--fix` never changes anything without asking. It shows you the exact command first, and you type `y` to run it or press Enter to skip.

## Requirements

- Any Linux system (Ubuntu, Debian, Fedora, WSL)
- Bash, which comes with Linux. Nothing to install.

## Built with

Bash, `/proc` and `/sys` (where Linux exposes system info), `df`, `ps`, `ss`, `systemctl`, and `journalctl`.

## Author

Ron Wiafe Jr. · [LinkedIn](https://linkedin.com/in/ron-wiafe-jr)
