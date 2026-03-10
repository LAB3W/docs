# My 2026 Protection / Security.

Pour tester ma Yubikey Bio ; j'ai pensé à utiliser une clef USB que j'ai crypté grâce à LUKS.

J'ai suivis le tutoriel d'Adrien de LinuxTriks.

Linuxtricks.fr / Cryptsetup : Créer une clé ou un disque USB chiffrée https://www.linuxtricks.fr/wiki/cryptsetup-creer-une-cle-ou-un-disque-usb-chiffree

### Outils LUKS

```bash
⛔🔜 root@srv-fr:~ # apt show cryptsetup
Package: cryptsetup
Version: 2:2.1.0-5+deb10u2
Priority: optional
Section: admin
Maintainer: Debian Cryptsetup Team <pkg-cryptsetup-devel@alioth-lists.debian.net>
Installed-Size: 69,6 kB
Depends: cryptsetup-initramfs (>= 2:2.0.3-1), cryptsetup-run (>= 2:2.0.3-1)
Homepage: https://gitlab.com/cryptsetup/cryptsetup
Tag: admin::boot, admin::filesystem, implemented-in::c,
 interface::commandline, role::program, scope::utility,
 security::cryptography, security::privacy, use::configuring
Download-Size: 51,5 kB
APT-Sources: http://archive.debian.org/debian buster/main amd64 Packages
Description: transitional dummy package for cryptsetup-{run,initramfs}
 This is a transitional dummy package to get upgrading systems to install the
 cryptsetup-run and cryptsetup-initramfs packages. It can safely be removed
 once no other package depends on it.
```

### Outils FIDO2

```bash
⛔🔜 root@srv-fr:~ # apt install fido2-tools pamu2fcfg libpam-u2f
```

---

## Ma clef USB (128G)

```bash
⛔🔜 root@srv-fr:~ # fdisk -l /dev/sdd
Disque /dev/sdd : 117,19 GiB, 125829120000 octets, 245760000 secteurs
Modèle de disque : ProductCode
Unités : secteur de 1 × 512 = 512 octets
Taille de secteur (logique / physique) : 512 octets / 512 octets
taille d'E/S (minimale / optimale) : 512 octets / 512 octets
Type d'étiquette de disque : dos
Identifiant de disque : 0x0a3170bc

Périphérique Amorçage    Début       Fin  Secteurs Taille Id Type
/dev/sdd1                 2048  10485760  10483713     5G  c W95 FAT32 (LBA)
/dev/sdd2             10487808 245759999 235272192 112,2G  5 Étendue
/dev/sdd5             10489856 245759999 235270144 112,2G 83 Linux
```

### Transformer la partition "`/dev/sdd5`" en partition cryptée 

```bash
⛔🔜 root@srv-fr:~ # cryptsetup --verify-passphrase luksFormat /dev/sdd5
```

ATTENTION !
===========
Cette action écrasera définitivement les données sur /dev/sdd5.

Êtes-vous sûr ? (Typez « yes » en majuscules) : YES
Saisissez la phrase secrète pour /dev/sdd5 :
Vérifiez la phrase secrète :
```

### J'ajoute ma Yubikey pour l'authentification de la clef 

#### Avant ; j'ai créé la, les clefs OpenSSL de cette manière ; çà crée les fichiers privé et public ; qui ne sont valident et associés seulement à la clef physique (Yubikey) ET à la méthode de l'authentificateur ; exemple par "fingerprint" (Bio) ou "PIN" et/ou "Touch" Only.

⛔🔜 root@srv-fr:~ # ssh-keygen -t ed25519-sk -O resident -O verify-required -O application=ssh:personalkey -C "orj@lab3w.fr"

Ce qui me créait les fichiers "`.ssh/id_ed25519_sk`" (la clef private) et "`.ssh/id_ed25519_sk.pub`" (la clef public). La clef publique doit être dans le fichier "`.ssh/authorized_keys`" des serveurs où je souhaite m'authentifier avec la "Yubikey".



### Puis j'ajoute ma "sk" pour l'authentification du disque USB.

```bash
⛔🔜 root@srv-fr:~ # systemd-cryptenroll /dev/sdd5 --fido2-device=auto --fido2-with-client-pin=no --fido2-with-user-presence=yes --fido2-with-user-verification=no
🔐 Please enter current passphrase for disk /dev/sdd5:
Initializing FIDO2 credential on security token.
👆 (Hint: This might require confirmation of user presence on security token.)
Generating secret key on FIDO2 security token.
👆 In order to allow secret key generation, please confirm presence on security token.
New FIDO2 token enrolled as key slot 1.
```

#### Information LUKS de la clef USB 

```bash
⛔🔜 root@srv-fr:~ # cryptsetup luksDump /dev/sdd5
LUKS header information
Version:        2
Epoch:          5
Metadata area:  16384 [bytes]
Keyslots area:  16744448 [bytes]
UUID:           5be8bdac-0134-4720-9a20-ac363859f090
Label:          (no label)
Subsystem:      (no subsystem)
Flags:          (no flags)

Data segments:
  0: crypt
        offset: 16777216 [bytes]
        length: (whole device)
        cipher: aes-xts-plain64
        sector: 512 [bytes]

Keyslots:
  0: luks2
        Key:        512 bits
        Priority:   normal
        Cipher:     aes-xts-plain64
        Cipher key: 512 bits
        PBKDF:      argon2id
        Time cost:  9
        Memory:     1048576
        Threads:    4
        Salt:       1c f0 80 06 3d d6 c5 c5 d4 86 ec 96 45 9b 72 f2
                    00 89 d7 f4 75 2d 97 f3 b5 67 5d 11 61 66 14 c4
        AF stripes: 4000
        AF hash:    sha256
        Area offset:32768 [bytes]
        Area length:258048 [bytes]
        Digest ID:  0
  1: luks2
        Key:        512 bits
        Priority:   normal
        Cipher:     aes-xts-plain64
        Cipher key: 512 bits
        PBKDF:      pbkdf2
        Hash:       sha512
        Iterations: 1000
        Salt:       98 58 30 6e 0a 66 de cf ee ad 3b 9b 6f 9b 4b 43
                    41 bf f1 f2 2e cc 25 b9 a8 7f 54 5e 53 4d 5c f2
        AF stripes: 4000
        AF hash:    sha512
        Area offset:290816 [bytes]
        Area length:258048 [bytes]
        Digest ID:  0
Tokens:
  0: systemd-fido2
        fido2-credential:
                    e9 cb 7d 89 e0 8f 6c 21 fe d8 eb 1d a4 c4 9b fb
                    da ef b5 c1 b1 ad 24 bd e4 58 74 70 53 5a f5 5b
                    0a 75 40 dd eb 96 71 37 26 5f 65 1f cb 37 1d 8e
                    5a bf ce f5 e2 f2 63 90 dd 1c 7b 64 6e a5 e1 6c
        fido2-salt: d7 1c b6 94 94 2e 50 28 ce f9 17 d6 56 8a bf 85
                    04 13 f3 a6 f0 5d d1 77 e9 d8 32 d6 7a eb 8f 64
        fido2-rp:   io.systemd.cryptsetup
        fido2-clientPin-required:
                    false
        fido2-up-required:
                    true
        fido2-uv-required:
                    false
        Keyslot:    1
Digests:
  0: pbkdf2
        Hash:       sha256
        Iterations: 139586
        Salt:       f6 46 c0 9b 4d 7a 45 21 81 20 2f 8a e1 62 57 08
                    a4 f4 0f 82 e5 ee e1 65 e4 5c 55 81 43 d6 82 d0
        Digest:     97 c0 eb 3c 45 59 27 30 f9 b4 6d dc 2e 2b bd a3
                    9d 4c 47 a1 4e 5c d5 36 f9 09 94 0c 71 32 2c 64
```

##### On ouvre la partition cryptée LUKS - pour ensuite la formater ; comme l'on souhaite.

Maintenant pour pouvoir travailler sur la clef ; il faut l'ouvrir (avec la clef ; 2 challenges d'authentifications ; 1. Il faut la clef physique ; 2. Il faut la Biométrie (ou le Touch). 

```bash
⛔🔜 root@srv-fr:~ # cryptsetup luksOpen /dev/sdd5 webcrypt
Asking FIDO2 token for authentication.
👆 Please confirm presence on security token to unlock.
mar. mars 10 17:07:25 ⛔🔜 root@srv-fr:~ # ll /dev/mapper/
total 0
crw------- 1 root root 10, 236  9 mars  15:28 control
lrwxrwxrwx 1 root root       7 10 mars  16:29 usbcrypt -> ../dm-0
lrwxrwxrwx 1 root root       7 10 mars  17:07 webcrypt -> ../dm-1
```

##### On formate la partition en Linux (ext4)

On peut maintenant formater la clef ; J'ai ajouter l'option "avoir un journal ext4" ; sinon je n'arrivais pas à "`mount -t ext4 ...`"

```bash
⛔🔜 root@srv-fr:~ # mke2fs -t ext4 -O ^has_journal /dev/mapper/webcrypt
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 29404672 4k blocks and 7356416 inodes
Filesystem UUID: 9d99e696-eba7-42fe-a3ef-748201749f92
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000, 7962624, 11239424, 20480000, 23887872

Allocating group tables: done
Writing inode tables: done
Writing superblocks and filesystem accounting information: done
```

##### On monte la partition 

```bash
⛔🔜 root@srv-fr:~ # mount /dev/mapper/webcrypt /mnt/webcrypt/
```

##### Rendu

```bash
⛔🔜 root@srv-fr:~ # df -h
Sys. de fichiers     Taille Utilisé Dispo Uti% Monté sur
udev                    32G       0   32G   0% /dev
tmpfs                  6,3G    3,1M  6,3G   1% /run
/dev/sda1               83G     24G   55G  30% /
/dev/sda6              366G    305G   43G  88% /var
/dev/mapper/usbcrypt    29G     40K   28G   1% /mnt/usbcrypt
/dev/mapper/webcrypt   111G    622M  105G   1% /mnt/webcrypt
```


### LinuxFR / Les bases de l'authentification, clé de sécurité FIDO2 sous Linux et Windows (23 novembre 2025)

https://linuxfr.org/users/usawa/journaux/les-bases-de-l-authentification-cle-de-securite-fido2-sous-linux-et-windows

### Debian-FR / FiDO2 : Web Authentication (WebAuthn) - NFC - Key biometric (mai 2022)

https://www.debian-fr.org/t/fido2-web-authentication-webauthn-nfc-key-biometric/86564

----

# Les entrées cachées ?

```bash
⛔🔜 root@srv-fr:~ # ls -l /dev/hidraw{0,1,2,3,4}
crw------- 1 root root 241, 0  9 mars  15:28 /dev/hidraw0
crw------- 1 root root 241, 1  9 mars  15:28 /dev/hidraw1
crw------- 1 root root 241, 2  9 mars  15:28 /dev/hidraw2
crw------- 1 root root 241, 3  9 mars  15:28 /dev/hidraw3
crw------- 1 root root 241, 4 10 mars  16:32 /dev/hidraw4
```

```bash
⛔🔜 root@srv-fr:~ # fido2-token -L
/dev/hidraw4: vendor=0x1050, product=0x0402 (Yubico YubiKey FIDO)
```

```bash
⛔🔜 root@srv-fr:~ # fido2-token -V
1.12.0
```

##### Sets the PIN of device.  The user will be prompted for the PIN.

```bash
⛔🔜 root@srv-fr:~ # fido2-token -S /dev/hidraw4
Enter new PIN for /dev/hidraw4:
```

`-S -a device`
- Enables CTAP 2.1 Enterprise Attestation on device.

##### Changes the PIN of device.  The user will be prompted for the current and new PINs.

```bash
⛔🔜 root@srv-fr:~ # fido2-token -C /dev/hidraw4
Enter current PIN for /dev/hidraw4:
Enter new PIN for /dev/hidraw4:
```

##### Prints the credential id (base64-encoded) and public key (PEM encoded) of the resident credential specified by rp_id and cred_id, where rp_id is a UTF-8 relying party id, and cred_id is a base64-encoded credential id.  The user will be prompted for the PIN.

```bash
⛔🔜 root@srv-fr:~ # fido2-token -I /dev/hidraw4
proto: 0x02
major: 0x05
minor: 0x06
build: 0x04
caps: 0x05 (wink, cbor, msg)
version strings: U2F_V2, FIDO_2_0, FIDO_2_1_PRE, FIDO_2_1
extension strings: credProtect, hmac-secret, largeBlobKey, credBlob, minPinLength
transport strings: usb
algorithms: es256 (public-key), eddsa (public-key), es384 (public-key)
aaguid: d8522d9f575b486688a9ba99fa02f35b
options: rk, up, uv, noplat, alwaysUv, credMgmt, authnrCfg, bioEnroll, clientPin, largeBlobs, pinUvAuthToken, setMinPINLength, nomakeCredUvNotRqd, credentialMgmtPreview, userVerificationMgmtPreview
fwversion: 0x50604
maxmsgsiz: 1280
maxcredcntlst: 8
maxcredlen: 128
maxlargeblob: 1024
maxrpids in minpinlen: 1
remaining rk(s): 22
minpinlen: 4
pin protocols: 2, 1
pin retries: 8
pin change required: false
uv retries: 3
platform uv attempt(s): 3
uv modality: 0x2 (fingerprint check)
sensor type: 1 (touch)
max samples: 16
```

`-I -k rp_id -i cred_id device`


---


##  WebAuthn + FIDO2

W3C Recommendation / Web Authentication: An API for accessing Public Key Credentials Level 2 (8 April 2021) https://www.w3.org/TR/webauthn-2/


### 

###### Korben.info

- Contourner la protection FIDO2 via une simple attaque MITM (6 mai 2024) https://korben.info/contourner-protections-cookies-faille-authentification-moderne.html

- Pocket ID - L'auth par passkey pour votre homelab (8 mars 2026) https://korben.info/pocket-id-auth-oidc-passkey.html

###### Bortzmeyer

- Jouons et sécurisons avec une clé FIDO2/WebAuthn 5 (29 janvier 2024) https://www.bortzmeyer.org/fido2-webauthn.html


### PingIdentity / Token Binding Comprendre son Concept et son Fonctionnement (25 févr. 2019)

https://www.pingidentity.com/fr/resources/blog/post/understanding-token-binding.html

---


### The Developer’s Practical Guide to Passwordless Authentication in 2026 (March 7, 2026)

https://securityboulevard.com/2026/03/the-developers-practical-guide-to-passwordless-authentication-in-2026/

---

#### Packagist : The PHP Package Repository

https://packagist.org/?query=webauthn



#### Symfony 7 Goes Passwordless: Your Step-by-Step Guide to WebAuthn (Nov 21, 2025)

https://medium.com/@laurentmn/symfony-7-goes-passwordless-your-step-by-step-guide-to-webauthn-a74783f9c667

#### GitHub / WebAuthn usage with JWT instead of cookies #39962 (Apr 9, 2024)

https://github.com/quarkusio/quarkus/issues/39962

Looking how we can use JWT instead of cookies for WebAuthn support.

#### Developers.yubico / java-webauthn-server

https://developers.yubico.com/java-webauthn-server/

#### Securing Web Applications with WebAuthn and Passkeys

https://phpconference.com/blog/webauthn-passkeys-secure-authentication/

Modern Web Authentication with PHP and JavaScript 



---

FIDO2 : Fast IDentity Online.

FIDO prend en charge une gamme complète de technologies d'authentification, y compris la biométrie – empreintes digitales et iris, reconnaissance vocale et faciale – ainsi que les solutions et les normes de communication existantes, telles que les modules de plateforme sécurisée (TPM), les jetons de sécurité USB, les éléments sécurisés intégrés (eSE), les cartes à puce et la communication en champ proche (NFC) - Source WikipediA : https://fr.wikipedia.org/wiki/Alliance_FIDO


CTAP : Client to Authenticator Protocol
MITM : Man-In-The-Middle

---

@LAB3W/O.Romain.Jaillet-ramey : +33 616****65
Freelance | Consultant LAMP (W3C.Master : Analyste.SSI/Dev.OpS)
ZW3B’s LAB3W : The Web’s Laboratory ; Engineering of the Internet.

