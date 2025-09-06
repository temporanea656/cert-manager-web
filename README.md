# Certificate Manager

Sistema modulare per la gestione di certificati CA (Certificate Authority) per uso hobbistico.

## 🚀 Caratteristiche

- **Gestione completa CA**: Creazione, verifica e gestione Certificate Authority
- **Certificati Server e Client**: Generazione automatica con configurazione SAN
- **Firma richieste esterne**: Importazione e firma di file CSR
- **Lista e rinnovo**: Monitoraggio scadenze e rinnovo certificati
- **Organizzazione automatica**: Struttura directory pulita e organizzata
- **Interface colorata**: Output chiaro con codici colore
- **Comando globale**: Disponibile da qualsiasi directory come `cert-manager`
- **Setup automatico workspace**: Configurazione completa ambiente Easy-RSA

## 📋 Prerequisiti

- **Easy-RSA**: Sistema di gestione PKI
- **OpenSSL**: Per operazioni crittografiche
- **Bash**: Shell Unix/Linux standard

### Installazione prerequisiti

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install easy-rsa openssl
```

**CentOS/RHEL:**
```bash
sudo yum install easy-rsa openssl
```

**Arch Linux:**
```bash
sudo pacman -S easy-rsa openssl
```

## 📁 Struttura del progetto

```
cert-manager/
├── cert-manager              # Script principale
├── install.sh               # Script di installazione
├── Makefile                 # Automazione installazione
├── README.md               # Questa documentazione
├── easyrsa                 # Template script Easy-RSA
├── openssl-easyrsa.cnf     # Template configurazione OpenSSL
├── vars                    # Template parametri CA
└── modules/                # Moduli funzionali
    ├── verificaCA.sh       # Verifica presenza CA
    ├── parametriVARS.sh    # Gestione parametri VARS
    ├── creazioneCA.sh      # Creazione Certificate Authority
    ├── creazioneSERVER.sh  # Generazione certificati server
    ├── creazioneCLIENT.sh  # Generazione certificati client
    ├── firmaCSR.sh         # Firma richieste certificate
    ├── listaCERTIFICATI.sh # Lista e gestione certificati
    └── rinnovoCERTIFICATI.sh # Rinnovo certificati
```

## 🔧 Installazione

### Metodo 1: Makefile (Raccomandato)

```bash
# Clona o scarica il progetto
git clone <repository-url> cert-manager
cd cert-manager

# Verifica i file
make check

# Installa come comando di sistema
sudo make install

# Verifica installazione
cert-manager --version
```

### Metodo 2: Script di installazione

```bash
# Rendi eseguibile lo script di installazione
chmod +x install.sh

# Installa completo
sudo ./install.sh

# Solo workspace Easy-RSA
sudo ./install.sh setup-workspace

# Disinstalla
sudo ./install.sh uninstall
```

### Metodo 3: Solo workspace (se hai già il comando)

```bash
# Setup solo ambiente di lavoro
sudo make setup-workspace
```

## 🎯 Comandi disponibili

### 🔧 **Makefile - Nuove funzionalità:**

- **`make check`** - Verifica file e workspace Easy-RSA (non installa)
- **`make install`** - Installazione completa (comando + workspace)
- **`make setup-workspace`** - Solo setup workspace Easy-RSA
- **`make info`** - Diagnostica completa del sistema
- **`make test`** - Verifica sintassi dei file
- **`make uninstall`** - Rimozione completa

### 🔧 **install.sh - Nuove funzionalità:**

- **`sudo ./install.sh`** - Installazione completa
- **`sudo ./install.sh setup-workspace`** - Solo setup workspace Easy-RSA
- **`sudo ./install.sh uninstall`** - Disinstallazione con opzioni
- **Setup automatico workspace** Easy-RSA in `/etc/easy-rsa`
- **Backup intelligente** di file esistenti in `backup.old/`

## 📂 **Struttura finale dopo installazione:**

```
/opt/cert-manager/          # Software installato
├── cert-manager           # Comando principale  
├── modules/              # Moduli funzionali
└── templates/            # File template

/etc/easy-rsa/             # Workspace operativo
├── easyrsa               # Script Easy-RSA
├── openssl-easyrsa.cnf   # Config OpenSSL
├── vars                  # Parametri CA
├── client/               # Certificati client
├── server/               # Certificati server  
├── pending-requests/     # CSR in attesa
├── signed-certificates/  # Certificati firmati
├── processed-requests/   # CSR processate
├── backup.old/          # Backup file esistenti
└── pki/                 # PKI (creata con CA)
```

## 🎯 Utilizzo

### Avvio del sistema

```bash
# Avvia il menu interattivo
cert-manager

# Verifica rapida del sistema
cert-manager --check

# Mostra l'aiuto
cert-manager --help
```

### Menu principale

```
===== MENU PRINCIPALE =====

1) Verifica dati CA
2) Gestisci parametri VARS per CA
3) Genera nuovo certificato CA
4) Genera certificato server
5) Genera certificato client
6) Genera certificato da richiesta
7) Lista e gestione certificati
8) Informazioni sistema
0) Esci
```

## 🏗️ Workflow tipico

### 1. Prima configurazione

1. **Installa Certificate Manager**: `sudo make install`
2. **Avvia Certificate Manager**: `cert-manager`
3. **Configura parametri VARS** (opzione 2):
   - Paese, provincia, città
   - Organizzazione ed email
   - Scadenze CA e certificati
4. **Crea Certificate Authority** (opzione 3)

### 2. Generazione certificati

**Per un server web:**
```bash
cert-manager
# Opzione 4 - Genera certificato server
# Inserisci: nome-server, IP, DNS
```

**Per un client:**
```bash
cert-manager
# Opzione 5 - Genera certificato client
# Inserisci: nome-client, email (opzionale)
```

### 3. Gestione certificati

```bash
cert-manager
# Opzione 7 - Lista certificati
# Visualizza scadenze e stato
# Rinnova certificati in scadenza
```

## 🔐 Gestione richieste certificate esterne

Per firmare richieste generate esternamente:

1. Copia il file `.csr` in `/etc/easy-rsa/pending-requests/`
2. Usa l'opzione 6 del menu
3. Il sistema analizza automaticamente la richiesta
4. Conferma il tipo (server/client) e firma
5. Il certificato viene spostato nella directory appropriata

## 🔄 Rinnovo certificati

Il sistema monitora automaticamente le scadenze:

- **Verde**: Certificato valido (>30 giorni)
- **Giallo**: In scadenza (7-30 giorni)
- **Rosso**: Scaduto o in scadenza critica (<7 giorni)

Per rinnovare:
1. Lista certificati (opzione 7)
2. Seleziona "Rinnova certificato"
3. Il sistema mantiene la stessa chiave privata
4. Genera nuovo certificato con stessa configurazione

## ⚙️ Configurazione avanzata

### Parametri VARS personalizzabili

```bash
# File: /etc/easy-rsa/vars

# Informazioni organizzazione
EASYRSA_REQ_COUNTRY="IT"
EASYRSA_REQ_PROVINCE="Tuscany"
EASYRSA_REQ_CITY="Prato"
EASYRSA_REQ_ORG="MyOrganization"
EASYRSA_REQ_EMAIL="admin@example.com"
EASYRSA_REQ_OU="IT Department"

# Scadenze (in giorni)
EASYRSA_CA_EXPIRE=3650        # CA: 10 anni
EASYRSA_CERT_EXPIRE=365       # Certificati: 1 anno

# Sicurezza
EASYRSA_KEY_SIZE=2048         # Dimensione chiave (2048/4096)
EASYRSA_DIGEST="sha512"       # Algoritmo hash
```

### Subject Alternative Names (SAN)

I certificati server supportano automaticamente:
- **DNS names**: `www.example.com`, `example.com`
- **IP addresses**: `192.168.1.100`, `10.0.0.1`

## 🚀 **Esempi di installazione:**

```bash
# Installazione completa
sudo make install

# Solo verifica (non installa)
make check

# Solo workspace  
sudo make setup-workspace

# Informazioni sistema
make info

# Con install.sh
sudo ./install.sh              # Completo
sudo ./install.sh setup-workspace  # Solo workspace
sudo ./install.sh uninstall    # Disinstallazione sicura
```

## 🔍 Risoluzione problemi

### Errore: "Easy-RSA non trovato"
```bash
# Installa Easy-RSA
sudo apt install easy-rsa     # Ubuntu/Debian
sudo yum install easy-rsa     # CentOS/RHEL
```

### Errore: "Permessi insufficienti"
```bash
# Assicurati di usare sudo per l'installazione
sudo make install
```

### Verifica completa del sistema
```bash
# Diagnostica completa
make info

# Verifica workspace
make check

# Test del comando
cert-manager --check
```

### Certificato non valido
```bash
# Verifica certificato
openssl x509 -in certificato.crt -text -noout

# Verifica catena di certificati
openssl verify -CAfile ca.crt certificato.crt
```

### Reset completo workspace
```bash
# ATTENZIONE: Elimina tutti i certificati!
sudo rm -rf /etc/easy-rsa
sudo make setup-workspace    # Ricrea workspace
cert-manager                 # Ricrea CA
```

## 🔧 Disinstallazione

### Con Makefile
```bash
sudo make uninstall
```

### Con script (più opzioni)
```bash
# Disinstallazione interattiva con scelta per workspace
sudo ./install.sh uninstall
```

### Manuale
```bash
sudo rm /usr/local/bin/cert-manager
sudo rm -rf /opt/cert-manager
# Opzionale: sudo rm -rf /etc/easy-rsa
```

## ✨ **Miglioramenti del sistema:**

1. **Comando globale**: Disponibile da qualsiasi directory
2. **Gestione parametri**: `--help`, `--version`, `--check`
3. **Verifica prerequisiti**: Controllo automatico Easy-RSA e OpenSSL
4. **Setup automatico workspace**: Configurazione completa `/etc/easy-rsa`
5. **Backup intelligente**: Salvataggio automatico file esistenti
6. **Installazione modulare**: Software in `/opt`, workspace in `/etc`
7. **Disinstallazione sicura**: Opzioni per mantenere certificati

## 📝 Note importanti

- **Backup regolari**: Esegui backup di `/etc/easy-rsa/`
- **Sicurezza chiavi**: Le chiavi private hanno permessi 600
- **Scadenze**: Monitora regolarmente le scadenze
- **Testing**: Testa sempre i certificati dopo la generazione
- **Uso hobbistico**: Questo sistema è progettato per ambienti di test/sviluppo
- **Workspace separato**: Software in `/opt`, dati operativi in `/etc/easy-rsa`

## 🤝 Contributi

Questo è un progetto per uso hobbistico. Suggerimenti e miglioramenti sono benvenuti!

## 📞 Supporto

Per problemi:
1. Controlla i log con `cert-manager --check`
2. Usa `make info` per diagnostica completa
3. Verifica workspace con `make check`

## 📄 Licenza

Progetto open source per uso hobbistico ed educativo.
