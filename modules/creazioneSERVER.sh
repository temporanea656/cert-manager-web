#!/bin/bash

# Funzione per generare un certificato server
generate_server_certificate() {
    # Raccolta informazioni per il certificato server
    echo -e "${BLUE}Inserisci le informazioni per il certificato server:${NC}"
    echo ""

    # Nome del certificato
    local cert_name
    while true; do
        read -p "Nome del certificato server (es: web-server, vpn-server): " cert_name
        if [ -n "$cert_name" ]; then
            # Rimuovi caratteri non validi e converti in minuscolo
            cert_name=$(echo "$cert_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]//g')
            if [ -n "$cert_name" ]; then
                break
            fi
        fi
        echo -e "${RED}Nome non valido. Usa solo lettere, numeri, punti, underscore e trattini.${NC}"
    done

    # Indirizzo IP del server
    local server_ip
    echo ""
    echo -e "${YELLOW}Inserisci l'indirizzo IP del server (opzionale, premi INVIO per saltare):${NC}"
    while true; do
        read -p "IP server: " server_ip
        if [ -z "$server_ip" ]; then
            break
        elif [[ $server_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            # Validazione IP semplificata
            IFS='.' read -ra ADDR <<< "$server_ip"
            valid=true
            for i in "${ADDR[@]}"; do
                if [ "$i" -gt 255 ] || [ "$i" -lt 0 ]; then
                    valid=false
                    break
                fi
            done
            if [ "$valid" = true ]; then
                break
            fi
        fi
        echo -e "${RED}Formato IP non valido. Usa il formato xxx.xxx.xxx.xxx${NC}"
    done
    
    # Nome DNS del server
    local dns_name
    echo ""
    echo -e "${YELLOW}Inserisci il nome DNS del server (opzionale, premi INVIO per saltare):${NC}"
    read -p "DNS name: " dns_name
    
    # Verifica che almeno uno tra IP e DNS sia specificato
    if [ -z "$server_ip" ] && [ -z "$dns_name" ]; then
        echo ""
        echo -e "${YELLOW}⚠ Attenzione: Nessun IP o DNS specificato.${NC}"
        echo -e "${YELLOW}Il certificato sarà valido solo per il Common Name.${NC}"
        echo ""
        local confirm
        while true; do
            read -p "Vuoi continuare comunque? (s/n): " confirm
            case $confirm in
                [Ss]|[Ss][Ii])
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    echo -e "${YELLOW}Operazione annullata.${NC}"
                    return 1
                    ;;
                *)
                    echo -e "${RED}Risposta non valida. Inserisci 's' per sì o 'n' per no.${NC}"
                    ;;
            esac
        done
    fi
    
    # Mostra riepilogo
    echo ""
    echo -e "${BLUE}===== RIEPILOGO CERTIFICATO SERVER =====${NC}"
    echo -e "Nome certificato: ${GREEN}$cert_name${NC}"
    echo -e "IP server: ${GREEN}${server_ip:-"Non specificato"}${NC}"
    echo -e "DNS name: ${GREEN}${dns_name:-"Non specificato"}${NC}"
    echo ""
    
    # Conferma finale
    local final_confirm
    while true; do
        read -p "Confermi la generazione del certificato? (s/n): " final_confirm
        case $final_confirm in
            [Ss]|[Ss][Ii])
                break
                ;;
            [Nn]|[Nn][Oo])
                echo -e "${YELLOW}Operazione annullata.${NC}"
                return 1
                ;;
            *)
                echo -e "${RED}Risposta non valida. Inserisci 's' per sì o 'n' per no.${NC}"
                ;;
        esac
    done
    
    # Genera il certificato
    create_server_certificate "$cert_name" "$server_ip" "$dns_name"
}    

# Funzione per creare effettivamente il certificato server
create_server_certificate() {
    local cert_name="$1"
    local server_ip="$2"
    local dns_name="$3"
    
    echo ""
    echo -e "${BLUE}Creazione certificato server...${NC}"
    
    # Cambia directory
    cd /etc/easy-rsa || {
        echo -e "${RED}✗ Errore: Impossibile accedere alla directory /etc/easy-rsa${NC}"
        return 1
    }
    
    # Prepara le variabili d'ambiente per SAN (Subject Alternative Names)
    local san_entries=""
    if [ -n "$server_ip" ] || [ -n "$dns_name" ]; then
        san_entries=""
        if [ -n "$server_ip" ]; then
            san_entries="IP:${server_ip}"
        fi
        if [ -n "$dns_name" ]; then
            if [ -n "$server_ip" ]; then
                san_entries="${san_entries},DNS:${dns_name}"
            else
                san_entries="DNS:${dns_name}"
            fi
        fi
    fi
    
    echo -e "${YELLOW}Generazione richiesta certificato per: $cert_name${NC}"
    
    # Crea un file temporaneo per il batch input (evita richieste interattive)
    local temp_input=$(mktemp)
    cat > "$temp_input" << 'EOF'



EOF
    
    # Imposta variabili per EasyRSA
    export EASYRSA_REQ_CN="$cert_name"
    export EASYRSA_BATCH="1"
    
    # Genera la richiesta di certificato (senza password)
    if [ -n "$san_entries" ]; then
        echo -e "${YELLOW}Con SAN: $san_entries${NC}"
        if ./easyrsa --subject-alt-name="$san_entries" gen-req "$cert_name" nopass < "$temp_input"; then
            echo -e "${GREEN}✓ Richiesta generata con SAN${NC}"
        else
            echo -e "${RED}✗ Errore durante la generazione della richiesta certificato con SAN!${NC}"
            rm -f "$temp_input"
            cd - > /dev/null
            return 1
        fi
    else
        if ./easyrsa gen-req "$cert_name" nopass < "$temp_input"; then
            echo -e "${GREEN}✓ Richiesta generata${NC}"
        else
            echo -e "${RED}✗ Errore durante la generazione della richiesta certificato!${NC}"
            rm -f "$temp_input"
            cd - > /dev/null
            return 1
        fi
    fi
    
    # Pulisci file temporaneo
    rm -f "$temp_input"
    
    echo ""
    echo -e "${YELLOW}Firma del certificato con la CA...${NC}"
    
    # Firma il certificato come server certificate
    if ./easyrsa sign-req server "$cert_name"; then
        echo ""
        echo -e "${GREEN}✓ Certificato server generato con successo!${NC}"
        
        # Crea la directory per il server specifico (seguendo la tua struttura)
        local server_dir="/etc/easy-rsa/$cert_name"
        echo ""
        echo -e "${BLUE}Preparazione directory server: $server_dir${NC}"
        
        if mkdir -p "$server_dir"; then
            echo -e "${GREEN}✓ Directory creata: $server_dir${NC}"
            
            # Sposta i file dalla struttura PKI alla directory del server
            local files_copied=0
            
            # Sposta il certificato
            if [ -f "/etc/easy-rsa/pki/issued/$cert_name.crt" ]; then
                if mv "/etc/easy-rsa/pki/issued/$cert_name.crt" "$server_dir/$cert_name.crt"; then
                    echo -e "${GREEN}✓ Certificato spostato: $server_dir/$cert_name.crt${NC}"
                    files_copied=$((files_copied + 1))
                else
                    echo -e "${RED}✗ Errore nello spostamento del certificato${NC}"
                fi
            fi
            
            # Sposta la chiave privata
            if [ -f "/etc/easy-rsa/pki/private/$cert_name.key" ]; then
                if mv "/etc/easy-rsa/pki/private/$cert_name.key" "$server_dir/$cert_name.key"; then
                    echo -e "${GREEN}✓ Chiave privata spostata: $server_dir/$cert_name.key${NC}"
                    # Imposta permessi sicuri per la chiave privata
                    chmod 600 "$server_dir/$cert_name.key"
                    echo -e "${YELLOW}✓ Permessi chiave privata impostati (600)${NC}"
                    files_copied=$((files_copied + 1))
                else
                    echo -e "${RED}✗ Errore nello spostamento della chiave privata${NC}"
                fi
            fi
            
            # Sposta la richiesta di certificato
            if [ -f "/etc/easy-rsa/pki/reqs/$cert_name.req" ]; then
                if mv "/etc/easy-rsa/pki/reqs/$cert_name.req" "$server_dir/$cert_name.req"; then
                    echo -e "${GREEN}✓ Richiesta spostata: $server_dir/$cert_name.req${NC}"
                    files_copied=$((files_copied + 1))
                else
                    echo -e "${RED}✗ Errore nello spostamento della richiesta${NC}"
                fi
            fi

            # Copia il certificato CA nella directory del server
            if [ -f "/etc/easy-rsa/pki/ca.crt" ]; then
                if cp "/etc/easy-rsa/pki/ca.crt" "$server_dir/ca.crt"; then
                    echo -e "${GREEN}✓ CA certificate copiato: $server_dir/ca.crt${NC}"
                    files_copied=$((files_copied + 1))
                else
                    echo -e "${RED}✗ Errore nella copia del CA certificate${NC}"
                fi
            fi

            # Crea un file README specifico per questo certificato
            cat > "$server_dir/$cert_name-README.txt" << EOF
Certificato Server: $cert_name
Generato il: $(date)
IP: ${server_ip:-"Non specificato"}
DNS: ${dns_name:-"Non specificato"}

File per questo server:
- $cert_name.crt: Certificato del server
- $cert_name.key: Chiave privata del server (permessi 600)
- $cert_name.req: Richiesta di certificato originale
- ca.crt: Certificato della Certificate Authority

Per utilizzare il certificato:
1. Configurare il server per usare $cert_name.crt e $cert_name.key
2. Distribuire ca.crt ai client per la verifica
3. Assicurarsi che il server abbia accesso a tutti i file

ATTENZIONE: La chiave privata ($cert_name.key) deve essere mantenuta segreta!

STRUTTURA DIRECTORY:
$server_dir/
├── $cert_name.crt      (Certificato server)
├── $cert_name.key      (Chiave privata - permessi 600)
├── $cert_name.req      (Richiesta originale)
├── ca.crt              (CA certificate)
└── $cert_name-README.txt (Questo file)
EOF
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ File README creato: $server_dir/$cert_name-README.txt${NC}"
                files_copied=$((files_copied + 1))
            fi
            
            echo ""
            echo -e "${BLUE}===== CERTIFICATO SERVER COMPLETATO =====${NC}"
            echo -e "Directory: ${GREEN}$server_dir${NC}"
            echo -e "Certificato: ${GREEN}$server_dir/$cert_name.crt${NC}"
            echo -e "Chiave privata: ${GREEN}$server_dir/$cert_name.key${NC}"
            echo -e "Richiesta: ${GREEN}$server_dir/$cert_name.req${NC}"
            echo -e "CA Certificate: ${GREEN}$server_dir/ca.crt${NC}"
            echo -e "Documentazione: ${GREEN}$server_dir/$cert_name-README.txt${NC}"
            echo ""
            echo -e "${GREEN}Totale file creati: $files_copied${NC}"
            
        else
            echo -e "${RED}✗ Errore nella creazione della directory $server_dir${NC}"
            echo -e "${YELLOW}I file rimangono nella struttura PKI standard.${NC}"
        fi
        
        echo ""
        echo -e "${BLUE}===== INFORMAZIONI CERTIFICATO =====${NC}"
        if [ -f "$server_dir/$cert_name.crt" ]; then
            openssl x509 -in "$server_dir/$cert_name.crt" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:|DNS:|IP Address:)" | sed 's/^[ \t]*//'
        elif [ -f "/etc/easy-rsa/pki/issued/$cert_name.crt" ]; then
            openssl x509 -in "/etc/easy-rsa/pki/issued/$cert_name.crt" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:|DNS:|IP Address:)" | sed 's/^[ \t]*//'
        fi
        
        echo ""
        echo -e "${GREEN}Il certificato server è pronto per l'uso!${NC}"
        echo -e "${BLUE}Directory completa: $server_dir${NC}"
    else
        echo ""
        echo -e "${RED}✗ Errore durante la firma del certificato!${NC}"
        echo -e "${YELLOW}Controlla i messaggi di errore sopra per maggiori dettagli.${NC}"
        cd - > /dev/null
        return 1
    fi

    # Torna alla directory originale
    cd - > /dev/null
}