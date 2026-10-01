Welcome to the README for the Purple Lab

This lab is made to simulate a real company with servers, computers, forest and end users.
So when you have to test something you can use this lab as a guinea pig without risking any real world damage.

================================================================================
  SECTION 1  -  REQUIRED TOOLS
================================================================================

The lab set up uses the following tools

Vmware
Vagrant
Ansible
Docker

Make sure that these are installed on your computer.

--------------------------------------------------------------------------------
  SUPPORTED PLATFORMS
--------------------------------------------------------------------------------

Linux ......... Yes (recommended)
Windows ....... Yes, but run Ansible from WSL2 and set up the 192.168.100.0/24
                host-only network manually in VMware.
Mac support ... None.

================================================================================
  SECTION 2  -  MACHINES
================================================================================

This lab contains 4 machines  
1 Domain controller 
1 Server 
1 Client 
1 Kali 

================================================================================
  SECTION 3  -  NETWORK, MACHINES & PASSWORDS
================================================================================

All machines sit on the same private network: 192.168.100.0/24
The domain controller (dc01) is also the DNS server for the domain.

Machine     IP                Role
dc01        192.168.100.10    Domain controller (lab.local)
srv01       192.168.100.20    Member server
client01    192.168.100.30    Member client
kali1       192.168.100.40    Attacker box

Domain: lab.local  (NetBIOS name: LAB)

--------------------------------------------------------------------------------
  FULL PASSWORD LIST  (isolated lab, so passwords are simple on purpose)
--------------------------------------------------------------------------------

ACCESS / LOGINS
  Vagrant / WinRM login .......... vagrant / vagrant
  Domain admin ................... vagrant@lab.local / vagrant
  DSRM (safe mode) ............... Password123!
  Kali console ................... vagrant / vagrant

DOMAIN USERS (created by create_users.yml, default pw unless noted)
  jqs (John Quincy Smith) ........ P@ssw0rd123!
  ald (Alice Doe) ................ P@ssw0rd123!
  bom (Bob Miller) ............... P@ssw0rd123!

BLOODHOUND CE (web UI at http://127.0.0.1:8080)
  admin .......................... Password123!

HONEYPOT ACCOUNTS (decoys - strong pw on purpose, NOT meant to be cracked)
  svc_sqladmin ................... Zx9#Kq2!vLp7$Rn4
  backup_svc ..................... Qm4$Tz8!wRb2#Yn6
  administrator_old .............. Hs7!Np3$xKd9#Vc2

INTENTIONAL VULN ACCOUNT (only exists after running vulns.yml - see Section 8)
  svc_sql (Domain Admin) ......... Password1     (weak, in rockyou.txt)

================================================================================
  SECTION 4  -  SYSTEM REQUIREMENTS
================================================================================
The specs that you need to have available to run this lab is 

Minimum CPU
Core i5-1135G7 / i5-1145G7
Ryzen 5 4600H / 5600H (6c/12t) or Ryzen 5 5500U

Minimum RAM
30 Gb
The lab uses 18Gb

Free storage 
150Gb
The lab uses 76Gb (the running VM disks). On top of that, the downloaded box
images (the cached base images) take about 60Gb more, so the real total on
disk is over 130Gb. Make sure you have room for both.

It is possible to downgrade some of the machines at the cost of performance
================================================================================
  SECTION 5  -  ABOUT VAGRANT
================================================================================
Why use Vagrant

The vision for this lab was to make an easy one line command to get it up and running.
With vagrant that vision was made possible.

In the folder /vagrant-project you can find the Vagrantfile.
This is the file where you can make new VMs, configure old machines and change settings.

In vagrant we use Providers and boxes
Providers are the software we use to make the VMs, in our case VMware. It is also here you can configure the machine for your needs 
Boxes are where we choose the image the machine will be running with,
there is nothing that has to be downloaded manually, you just have to point at the image you want.

Here you can see how to point at the machine 
dc01.vm.box = "gusztavvargadr/windows-server-2025-standard"

dc01 is the name of the machine.
.vm is the configuration namespace for that machine.
.box is the setting that picks the image.
The provider (VMware) is configured separately in the same block.
 
There are many options to choose from and it is important that you choose one that fits your provider and hardware.

Boxes can be found at 
https://portal.cloud.hashicorp.com/vagrant/discover

First time you access this lab it will take about 30-40 minutes, because it has to configure all the machines.

Vagrant can also run scripts when it is started, so if you want a specific configuration to run on the OS level,
scripts are the way to do it.
Scripts are kept in the scripts folder and pointed to via the Vagrantfile,
so it is easy for you to make your own if needed.
When Vagrant is started, it will automatically run the scripts listed in the Vagrantfile.
 
An example of where and how we use scripts can be seen here.
This is in the Vagrantfile:
 dc01.vm.provision "shell",
      path: "scripts/lang.ps1"


This is the script to configure the language on the machine

Write-Host "Configuring timezone..."
Set-TimeZone -Id "Romance Standard Time"

Write-Host "Configuring Danish keyboard..."
$LanguageList = New-WinUserLanguageList -Language "da-DK"
Set-WinUserLanguageList $LanguageList -Force

Write-Host "Baseline configuration completed."
 
--------------------------------------------------------------------------------
  EXPANDING THE INFRASTRUCTURE  (adding a new machine)
--------------------------------------------------------------------------------

You add a machine by copying an existing block in the Vagrantfile and changing a
few values. To add another Windows member server (call it srv02, IP .21):

1. In the Vagrantfile, copy the whole srv01 block (config.vm.define "srv01" ...
   through its matching end) and paste it below. In the copy, change:
     - the name in both places:  "srv01"   -> "srv02"
     - the IP:                   192.168.100.20 -> 192.168.100.21
     - memory/cpus if you want a smaller box
   Keep the box, the lang.ps1 and dcjoin.ps1 provisioners the same - dcjoin.ps1
   is what joins it to the domain on first boot. Pick an IP that is free on the
   192.168.100.0/24 network (10/20/30/40 are already used).

2. Tell Ansible about it. In ansible/inventory.ini add the new host under the
   right group so the playbooks reach it over WinRM:
     [members]
     srv01 ansible_host=192.168.100.20
     client01 ansible_host=192.168.100.30
     srv02 ansible_host=192.168.100.21      <- new line
   (A domain controller would go under [dc]; a member server or client goes
   under [members]. The [windows:vars] block already gives it the WinRM login.)

3. Bring it up and configure it:
     cd ./vagrant-project/
     vagrant up srv02
     cd ansible/
     ansible-playbook ping.yml        # confirm it answers (unreachable=0)
     ansible-playbook site.yml        # joins it + re-applies everything (idempotent)

Notes:
  - A Linux/attacker box (like Kali) uses communicator = "ssh" and is NOT added
    to the inventory - Ansible does not manage it. Copy the kali1 block instead
    of the srv01 block for that.
  - Watch your host resources. Each Windows box wants ~4-5 GB RAM (see Section 4);
    adding machines adds up fast.
  - To remove a machine: vagrant destroy <name>, delete its Vagrantfile block,
    and remove its inventory.ini line.

================================================================================
  SECTION 6  -  QUICK START (whole lab in one command)
================================================================================

You do not have to run Vagrant and Ansible by hand. There is a script in the
project root, bootstrap.sh, that brings the entire lab up in the correct order:
it starts the domain controller first, then the server and client, then Kali,
then runs the full Ansible build AND the monitoring: promote -> join -> create
users -> password policy -> Sysmon + honeypots -> enable LDAPS (for BloodHound).

Just run this one line from anywhere:

./vagrant-project/bootstrap.sh

Options:
./bootstrap.sh --no-kali        start everything except the Kali box
./bootstrap.sh --no-monitoring  build the domain only (skip Sysmon + honeypots)
./bootstrap.sh --no-ldaps       skip enabling LDAPS on the DC
./bootstrap.sh --ansible        skip Vagrant, only (re)run the Ansible playbooks
./bootstrap.sh --help           show the built-in help

================================================================================
  SECTION 7  -  VAGRANT COMMANDS TO KNOW
================================================================================
Although we can run bootstrap.sh to start up the machines, it is a good idea to have a basic knowledge of how Vagrant works.
I have made a list of the most used Vagrant commands here. 

First you have to make sure, that you are in the right folder, where the Vagrantfile is located 
./vagrant-project/ 

vagrant up - all machines are started, all scripts are run, no exceptions

If you only want some of the machines you can type (vagrant up dc01 srv01 client01)
You can also run it without any scripts (vagrant up --no-provision)  

vagrant halt - stops the machines.

vagrant status - shows the state of the machines.

vagrant reload - restarts the machines.

vagrant destroy - destroys the machines (only use this when you break the machine, you have to start all over after this command)

================================================================================
  SECTION 8  -  HOW TO USE ANSIBLE
================================================================================
Vagrant builds the empty machines. Ansible is what turns them into a real domain -
it promotes the domain controller, joins the server and client, creates the users,
sets the password policy, and installs the monitoring (Sysmon + honeypots).

All Ansible commands are run from the ansible folder, not the project root:
cd ./vagrant-project/ansible/

The ansible.cfg in that folder points at inventory.ini automatically, so you do not
have to pass -i every time.

Inventory (inventory.ini) - who Ansible talks to:
[dc]      - dc01
[members] - srv01, client01
[windows] - both of the above (connects over WinRM on port 5985)

The order to run things:

1. Test the connection first
   ansible-playbook ping.yml
   This just checks that Ansible can reach every Windows machine. You want to see
   unreachable=0 and failed=0.

2. Build the whole domain
   ansible-playbook site.yml
   This runs the full build in the right order: promote dc01 -> join srv01 and
   client01 -> create users -> apply the password policy. It reboots machines
   along the way, so it takes a few minutes. It is safe to run again - anything
   already done is skipped.

3. Install the monitoring
   ansible-playbook sysmon.yml       (installs Sysmon on all Windows machines)
   ansible-playbook honeypots.yml    (creates the decoy accounts on the DC)

4. Watch the lab live
   On the dc01 console, in an admin PowerShell:
   C:\vagrant\scripts\honey-watch.ps1
   Anything that touches a honeypot account shows up in red.

5. After attacking from Kali, see what tripped
   ansible-playbook honey_detect.yml
   ansible-playbook honey_detect.yml -e hours=1   (only look at the last hour)

Adding your own users, and setting/changing passwords:
Users are just a list in ansible/group_vars/dc.yml. To ADD a user, add a line
to the 'users:' list, then re-run the playbook:
   users:
     - { first: "Carol", last: "King", groups: ["HR"] }
   cd ./vagrant-project/ansible/
   ansible-playbook create_users.yml

The login/UPN is built automatically from the name - with a middle name it uses
the initials (John Quincy Smith -> jqs), without one it uses the first two
letters of the first name plus the first letter of the last name (Alice Doe ->
ald). Everyone ends with @lab.local.

Setting a specific password for a user:
Each user can carry its own 'password'. If you leave it out, the user gets the
default (P@ssw0rd123!, set at the top of create_users.yml):
   - { first: "Carol", last: "King", password: "Winter2026-lab-pass", groups: ["HR"] }

IMPORTANT - the 16-character rule for users added AFTER the first build:
The domain enforces a 16-character minimum (password_policy.yml). The default
seed password is only 12 chars - that works during the very first build because
site.yml applies the policy LAST, after the users exist. But once the lab is
built the policy is already live, so any NEW user you add must be given a
password of at least 16 characters and meeting complexity (upper + lower + digit
+ special), or the create will fail the length rule. Example that satisfies it:
"Winter2026-lab-pass".

IMPORTANT - changing an EXISTING user's password:
create_users.yml uses update_password: on_create, so just editing 'password' in
the list and re-running does NOT rotate an existing account - it only sets the
password when the account is first made. To actually change a live user's
password, set it on the DC directly. In an admin PowerShell on dc01:
   Set-ADAccountPassword -Identity jqs -Reset `
     -NewPassword (ConvertTo-SecureString "New-16char-pass-here" -AsPlainText -Force)
(Remember the 16-char minimum applies here too.) Then update the password list
in dc.yml and the FULL PASSWORD LIST in Section 3 so the docs stay honest.

Adding honeypots works the same way - edit the honey_users list in dc.yml and
re-run honeypots.yml. Honeypot passwords are deliberately strong and are NOT
subject to on_create only on the initial deploy; see honeypots.yml if you need
to rotate one.

Playbooks at a glance:
ping.yml            - connection test
site.yml            - full domain build (promote + join + users + policy)
promote_dc.yml      - just promote dc01 to a domain controller
join_domain.yml     - just join srv01 and client01
create_users.yml    - just the OUs, groups and users
password_policy.yml - just the password and lockout policy
sysmon.yml          - install Sysmon
honeypots.yml       - deploy the honeypot accounts
honey_detect.yml    - hunt for honeypot hits in the logs
enable_ldaps.yml    - give the DC an LDAPS cert (needed for BloodHound)
vulns.yml           - plant the intentional vuln (see Section 9). OPT-IN.

================================================================================
  SECTION 9  -  MAKING THE LAB BREAKABLE (intentional vuln)
================================================================================
For practice / testing exploit tooling, the lab can be made deliberately
breakable. This is OPT-IN and is NOT part of bootstrap.sh or site.yml.

Turn it on:
   cd ./vagrant-project/ansible/
   ansible-playbook vulns.yml

Turn it off (clean the lab back up):
   ansible-playbook vulns.yml -e vuln_state=absent

What it plants: a service account svc_sql that is a Domain Admin, is
Kerberoastable, and has a weak password (Password1) that lives in rockyou.txt.
The easiest full breach, from Kali:
   1. Kerberoast    impacket-GetUserSPNs lab.local/vagrant:vagrant -dc-ip 192.168.100.10 -request-user svc_sql -outputfile hash.txt
   2. Crack         john --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
   3. Domain Admin  the cracked password logs you in as svc_sql (Domain Admins)

Note: svc_sql is separate from the honeypot accounts, so turning the vuln on
does not interfere with the honeypot/detection lab.

================================================================================
  SECTION 10  -  BLOODHOUND (Dockerized)
================================================================================
BloodHound Community Edition runs in Docker to map the domain's attack paths.
Full details are in bloodhound/README.md. In short:

   cd ./vagrant-project/bloodhound/
   docker compose up -d          # start the web app (http://127.0.0.1:8080)
   docker build -t lab-bh-collector:latest collector/   # build collector (once)
   ./collect.sh                  # collect from the DC -> zip in collections/
   BH_ADMIN_PASS=Password123! ./ingest.sh   # upload the zip into BloodHound

Web UI login: admin / Password123!  (see the password list in Section 3).
LDAPS on the DC is required for collection - bootstrap.sh does this, or run
ansible-playbook enable_ldaps.yml by hand.

================================================================================
  SECTION 11  -  TROUBLESHOOTING
================================================================================

Kali fails on first boot with "not ready for guest communication"
   This happens while Kali is setting up its private network card. The machine
   itself is fine - it is a known timing issue, not a real error. Just bring it
   up again:
       vagrant reload kali1
   Then check that the lab IP is there:
       vagrant ssh kali1 -c "ip -4 addr show eth1"    (should show 192.168.100.40)

vagrant up fails with "vmnet devices are failing to start"
   VMware's network devices are down, usually after a Linux kernel update that
   left the VMware kernel modules unbuilt. Rebuild them, then try again:
       sudo vmware-modconfig --console --install-all
       sudo systemctl restart vmware
   Confirm the interfaces exist:
       ip -br link show | grep vmnet

Ansible cannot reach a Windows machine (unreachable in the ping test)
   The machine is probably still booting or rebooting after provisioning. Wait
   a minute and run the ping test again - it is safe to repeat:
       ansible-playbook ping.yml
   You can also confirm WinRM is open from the host:
       nc -w3 -z 192.168.100.10 5985     (10/20/30 = dc01/srv01/client01)

The invisible mouse cursor in the Kali window
   The cursor works but is not drawn (a VMware graphics driver quirk). It is
   already fixed in this lab with a small Xorg config, but if you rebuild Kali
   from scratch the fix is lost. Re-apply it by copying
   scripts/20-modesetting-swcursor.conf into the guest at
   /etc/X11/xorg.conf.d/ and restarting the display manager:
       sudo systemctl restart lightdm

Shutting the lab down cleanly
   Do not just close the laptop lid - suspending the host can wedge the Windows
   machines. Stop them properly instead:
       vagrant halt
   And to start again next time:
       vagrant up      (or ./bootstrap.sh)

Note on the Windows boxes
   The Windows Server and Windows 11 images are Evaluation editions, so they are
   time-limited. That is fine for a lab, just be aware they are not meant for
   permanent use.

================================================================================
  SECTION 12  -  FULL COMMAND LIST (cheat sheet)
================================================================================
Every command you need to run the lab, start to finish. Paths assume you cloned
the project as ./vagrant-project/.

--------------------------------------------------------------------------------
  0. ONE-LINER (does everything)
--------------------------------------------------------------------------------
   ./vagrant-project/bootstrap.sh
       Boots all VMs in order, builds the domain, installs Sysmon + honeypots,
       and enables LDAPS. This is all most people need.

--------------------------------------------------------------------------------
  1. VAGRANT (run from ./vagrant-project/)
--------------------------------------------------------------------------------
   cd ./vagrant-project/
   vagrant up                       start all machines (+ run provisioning)
   vagrant up dc01 srv01 client01   start only these machines
   vagrant up --no-provision        start without running scripts
   vagrant status                   show machine states
   vagrant halt                     stop all machines cleanly
   vagrant reload kali1             restart one machine (e.g. after Kali net fix)
   vagrant ssh kali1                open a shell on Kali
   vagrant destroy                  delete the machines (full rebuild needed after)

--------------------------------------------------------------------------------
  2. ANSIBLE - build & configure (run from ./vagrant-project/ansible/)
--------------------------------------------------------------------------------
   cd ./vagrant-project/ansible/
   ansible-playbook ping.yml            test WinRM to every Windows host
   ansible-playbook site.yml            full domain build (promote+join+users+policy)
   ansible-playbook sysmon.yml          install Sysmon everywhere
   ansible-playbook honeypots.yml       deploy the honeypot decoy accounts
   ansible-playbook enable_ldaps.yml    give the DC an LDAPS cert (for BloodHound)
   ansible-playbook honey_detect.yml            hunt honeypot hits (last 24h)
   ansible-playbook honey_detect.yml -e hours=1 hunt honeypot hits (last 1h)

--------------------------------------------------------------------------------
  3. MAKE IT BREAKABLE (intentional vuln - opt-in)
--------------------------------------------------------------------------------
   cd ./vagrant-project/ansible/
   ansible-playbook vulns.yml                    plant the vuln (svc_sql)
   ansible-playbook vulns.yml -e vuln_state=absent   remove the vuln

--------------------------------------------------------------------------------
  4. BLOODHOUND (Docker - run from ./vagrant-project/bloodhound/)
--------------------------------------------------------------------------------
   cd ./vagrant-project/bloodhound/
   docker compose up -d                          start the web app (127.0.0.1:8080)
   docker build -t lab-bh-collector:latest collector/   build collector (once)
   ./collect.sh                                  collect from the DC -> zip
   BH_ADMIN_PASS=Password123! ./ingest.sh        upload the zip into BloodHound
   docker compose down                           stop (keep data)
   docker compose down -v                        stop and wipe the databases
       Web UI login: admin / Password123!
