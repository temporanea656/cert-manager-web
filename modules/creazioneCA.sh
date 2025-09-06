#!/bin/bash

# Funzione per creare effettivamente i file CA
create_ca_files() {
    echo ""
    echo -e "${BLUE}Creazione nuova Certificate Authority...${NC}"
    
    # Verifica che la directory easy-rsa esista
    if [ ! -d "/etc/easy-rsa" ]; then
        echo -e "${RED}✗ Errore: Directory /etc/easy-rsa non trovata!${NC}"
        echo -e "${YELLOW}Assicurati che easy-rsa sia installato e configurato.${NC}"
        return 1
    fi
    
    # Verifica che il comando easyrsa esista
    if [ ! -f "/etc/easy-rsa/easyrsa" ]; then
        echo -e "${RED}✗ Errore: Script easyrsa non trovato in /etc/easy-rsa/!${NC}"
        echo -e "${YELLOW}Verifica l'installazione di easy-rsa.${NC}"
        return 1
    fi
    
    # Verifica che il file vars esista
    if [ ! -f "/etc/easy-rsa/vars" ]; then
        echo -e "${RED}✗ Errore: File vars non trovato!${NC}"
        echo -e "${YELLOW}Prima di creare la CA, configura i parametri VARS (opzione 2 del menu).${NC}"
        return 1
    fi
    
    # Cambia directory ed esegui il comando easyrsa
    cd /etc/easy-rsa || {
        echo -e "${RED}✗ Errore: Impossibile accedere alla directory /etc/easy-rsa${NC}"
        return 1
    }
    
    # Conferma prima di procedere
    echo -e "${YELLOW}ATTENZIONE: Questa operazione eliminerà una eventuale CA esistente!${NC}"
    echo ""
    local confirm
    while true; do
        read -p "Vuoi continuare con la creazione della nuova CA? (s/n): " confirm
        case $confirm in
            [Ss]|[Ss][Ii])
                break
                ;;
            [Nn]|[Nn][Oo])
                echo -e "${YELLOW}Operazione annullata.${NC}"
                cd - > /dev/null
                return 0
                ;;
            *)
                echo -e "${RED}Risposta non valida. Inserisci 's' per sì o 'n' per no.${NC}"
                ;;
        esac
    done
    
    echo ""
    echo -e "${YELLOW}Pulizia directory PKI esistente...${NC}"
    
    # Rimuovi completamente la directory PKI esistente
    if [ -d "/etc/easy-rsa/pki" ]; then
        rm -rf /etc/easy-rsa/pki
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Directory PKI esistente rimossa${NC}"
        else
            echo -e "${RED}✗ Errore nella rimozione della directory PKI${NC}"
            cd - > /dev/null
            return 1
        fi
    fi
    
    echo -e "${YELLOW}Inizializzazione nuova PKI...${NC}"
    if ! ./easyrsa init-pki; then
        echo -e "${RED}✗ Errore durante l'inizializzazione PKI!${NC}"
        cd - > /dev/null
        return 1
    fi
    echo -e "${GREEN}✓ PKI inizializzata con successo${NC}"
    
    echo -e "${YELLOW}Copia file di configurazione...${NC}"
    
    # Cerca e copia il file di configurazione OpenSSL
    local openssl_config=""
    local possible_configs=(
        "/etc/easy-rsa/openssl-easyrsa.cnf"
        "/usr/share/easy-rsa/openssl-easyrsa.cnf"
        "/usr/share/easy-rsa/openssl-1.0.cnf"
        "/usr/share/easy-rsa/3/openssl-easyrsa.cnf"
        "/usr/share/easy-rsa/3.0/openssl-easyrsa.cnf"
        "./openssl-easyrsa.cnf"
    )
    
    for config in "${possible_configs[@]}"; do
        if [ -f "$config" ]; then
            openssl_config="$config"
            echo -e "${GREEN}✓ Trovata configurazione OpenSSL: $config${NC}"
            break
        fi
    done
    
    if [ -n "$openssl_config" ]; then
        if cp "$openssl_config" /etc/easy-rsa/pki/; then
            echo -e "${GREEN}✓ File di configurazione copiato in PKI${NC}"
        else
            echo -e "${YELLOW}⚠ Impossibile copiare il file di configurazione${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ File di configurazione OpenSSL non trovato nelle posizioni standard${NC}"
        echo -e "${YELLOW}  Procedo comunque...${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Creazione Certificate Authority...${NC}"
    echo -e "${BLUE}Modalità: Organizzazione (utilizzerà tutti i parametri VARS)${NC}"
    echo ""
    
    # Rimuovi eventuali file vars dalla PKI per evitare conflitti
    rm -f /etc/easy-rsa/pki/vars 2>/dev/null
    
    # Crea la CA in modalità batch (senza password) usando i parametri VARS
    # IMPORTANTE: Usa modalità organizzazione (non cn_only) per utilizzare tutti i parametri VARS
    if EASYRSA_BATCH=1 EASYRSA_REQ_CN_ONLY=0 ./easyrsa build-ca nopass; then
        echo ""
        echo -e "${GREEN}✓ Nuova CA generata con successo!${NC}"
        
        # Verifica i file generati
        if [ -f "/etc/easy-rsa/pki/ca.crt" ] && [ -f "/etc/easy-rsa/pki/private/ca.key" ]; then
            echo -e "${GREEN}✓ File CA verificati:${NC}"
            echo -e "  • Certificato CA: ${GREEN}/etc/easy-rsa/pki/ca.crt${NC}"
            echo -e "  • Chiave privata CA: ${GREEN}/etc/easy-rsa/pki/private/ca.key${NC}"
            
            # Mostra informazioni sulla CA appena creata
            echo ""
            echo -e "${BLUE}===== INFORMAZIONI CA CREATA =====${NC}"
            openssl x509 -in /etc/easy-rsa/pki/ca.crt -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:|Signature Algorithm:)" | sed 's/^[ \t]*//'
            
        else
            echo -e "${RED}✗ Errore: File CA non trovati dopo la generazione${NC}"
            cd - > /dev/null
            return 1
        fi
        
        # Aggiorna la variabile CAyes per le altre funzioni
        CAyes="true"
        echo ""
        echo -e "${GREEN}Certificate Authority pronta per l'uso!${NC}"
        
    else
        echo ""
        echo -e "${RED}✗ Errore durante la generazione della CA!${NC}"
        cd - > /dev/null
        return 1
    fi
    
    # Torna alla directory originale
    cd - > /dev/null
    
    # Riverifica i file CA per aggiornare lo stato globale
    echo ""
    echo -e "${BLUE}Riverifica finale dei file CA...${NC}"
    check_ca_files
}