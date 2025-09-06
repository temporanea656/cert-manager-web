#!/bin/bash

# Funzione per rinnovare un certificato (chiamata da listaCERTIFICATI.sh)
renew_certificate_menu() {
    local total_certs="$1"
    
    echo ""
    echo -e "${BLUE}===== RINNOVO CERTIFICATO =====${NC}"
    echo ""
    echo -e "${YELLOW}Inserisci il numero del certificato da rinnovare [1-$total_certs]:${NC}"
    
    local cert_number
    read -p "Numero: " cert_number
    
    if [[ "$cert_number" =~ ^[0-9]+$ ]] && [ "$cert_number" -ge 1 ] && [ "$cert_number" -le "$total_certs" ]; then
        local cert_path
        local cert_type
        
        if find_certificate_by_number "$cert_number" cert_path cert_type; then
            renew_single_certificate "$cert_path" "$cert_type"
            
            echo ""
            read -p "Premi INVIO per tornare alla lista certificati..."
            clear
            list_certificates
        else
            echo -e "${RED}✗ Certificato non trovato${NC}"
            echo ""
            read -p "Premi INVIO per tornare alla lista certificati..."
            clear
            list_certificates
        fi
    else
        echo -e "${RED}Numero non valido${NC}"
        echo ""
        read -p "Premi INVIO per tornare alla lista certificati..."
        clear
        list_certificates
    fi
}

# Funzione per rinnovare un singolo certificato
renew_single_certificate() {
    local cert_path="$1"
    local cert_type="$2"
    local cert_name=$(basename "$cert_path" .crt)
    local cert_dir=$(dirname "$cert_path")
    
    echo ""
    echo -e "${BLUE}Rinnovo certificato: $cert_name${NC}"
    echo -e "Tipo: ${GREEN}${cert_type^^}${NC}"
    echo -e "Percorso: ${GREEN}$cert_path${NC}"
    
    # Conferma
    local confirm
    while true; do
        read -p "Confermi il rinnovo? (s/n): " confirm
        case $confirm in
            [Ss]|[Ss][Ii])
                break
                ;;
            [Nn]|[Nn][Oo])
                echo -e "${YELLOW}Rinnovo annullato${NC}"
                return 0
                ;;
            *)
                echo -e "${RED}Risposta non valida. Inserisci 's' per sì o 'n' per no.${NC}"
                ;;
        esac
    done
    
    # Procedi con il rinnovo
    if [ "$cert_type" = "server" ]; then
        renew_server_certificate "$cert_path"
    elif [ "$cert_type" = "client" ]; then
        renew_client_certificate "$cert_path"
    else
        echo -e "${RED}✗ Tipo certificato non supportato: $cert_type${NC}"
        return 1
    fi
}

# Funzione per rinnovare un certificato server
renew_server_certificate() {
    local cert_path="$1"
    local cert_name=$(basename "$cert_path" .crt)
    local cert_dir=$(dirname "$cert_path")
    
    echo ""
    echo -e "${BLUE}Rinnovo certificato server: $cert_name${NC}"
    
    # Verifica chiave esistente
    local key_path="$cert_dir/$cert_name.key"
    if [ ! -f "$key_path" ]; then
        echo -e "${RED}✗ Errore: Chiave privata non trovata: $key_path${NC}"
        return 1
    fi
    
    # Estrai SAN dal certificato esistente se presente
    local san_info=$(openssl x509 -in "$cert_path" -text -noout 2>/dev/null | grep -A1 "Subject Alternative Name" | tail -1 | sed 's/^[ \t]*//; s/DNS:/DNS:/g; s/IP Address:/IP:/g')
    
    # Cambia directory
    cd /etc/easy-rsa || {
        echo -e "${RED}✗ Errore: Impossibile accedere alla directory /etc/easy-rsa${NC}"
        return 1
    }
    
    echo -e "${YELLOW}Generazione nuova richiesta certificato...${NC}"
    
    # Pulisci eventuali file temporanei esistenti
    rm -f "/etc/easy-rsa/pki/reqs/$cert_name.req" 2>/dev/null
    rm -f "/etc/easy-rsa/pki/issued/$cert_name.crt" 2>/dev/null
    rm -f "/etc/easy-rsa/pki/private/$cert_name.key" 2>/dev/null
    
    # Crea file temporaneo per input automatico
    local temp_input=$(mktemp)
    cat > "$temp_input" << 'EOF'



EOF
    
    # Imposta variabili per EasyRSA
    export EASYRSA_REQ_CN="$cert_name"
    export EASYRSA_BATCH="1"
    
    # Genera richiesta con SAN se presente
    if [ -n "$san_info" ]; then
        echo -e "${YELLOW}Usando SAN: $san_info${NC}"
        if ./easyrsa --subject-alt-name="$san_info" gen-req "$cert_name" nopass < "$temp_input"; then
            echo -e "${GREEN}✓ Richiesta generata con SAN${NC}"
        else
            echo -e "${RED}✗ Errore durante la generazione della richiesta con SAN${NC}"
            rm -f "$temp_input"
            cd - > /dev/null
            return 1
        fi
    else
        if ./easyrsa gen-req "$cert_name" nopass < "$temp_input"; then
            echo -e "${GREEN}✓ Richiesta generata${NC}"
        else
            echo -e "${RED}✗ Errore durante la generazione della richiesta${NC}"
            rm -f "$temp_input"
            cd - > /dev/null
            return 1
        fi
    fi
    
    # Pulisci file temporaneo
    rm -f "$temp_input"
    
    # Sostituisci la chiave generata con quella originale
    if cp "$key_path" "/etc/easy-rsa/pki/private/$cert_name.key"; then
        echo -e "${GREEN}✓ Chiave privata originale ripristinata${NC}"
    else
        echo -e "${RED}✗ Errore nel ripristino della chiave privata${NC}"
        cd - > /dev/null
        return 1
    fi
    
    echo ""
    echo -e "${YELLOW}Firma del nuovo certificato...${NC}"
    
    # Firma il nuovo certificato
    if ./easyrsa sign-req server "$cert_name"; then
        echo ""
        echo -e "${GREEN}✓ Nuovo certificato generato con successo!${NC}"
        
        # Sposta il nuovo certificato al posto di quello vecchio
        if mv "/etc/easy-rsa/pki/issued/$cert_name.crt" "$cert_path"; then
            echo -e "${GREEN}✓ Certificato rinnovato: $cert_path${NC}"
        else
            echo -e "${RED}✗ Errore nel posizionamento del nuovo certificato${NC}"
            cd - > /dev/null
            return 1
        fi
        
        # Pulizia file temporanei
        rm -f "/etc/easy-rsa/pki/reqs/$cert_name.req" 2>/dev/null
        
        echo ""
        echo -e "${GREEN}✓ Rinnovo completato con successo!${NC}"
        
    else
        echo ""
        echo -e "${RED}✗ Errore durante la firma del certificato${NC}"
        cd - > /dev/null
        return 1
    fi
    
    cd - > /dev/null
}

# Funzione per rinnovare un certificato client
renew_client_certificate() {
    local cert_path="$1"
    local cert_name=$(basename "$cert_path" .crt)
    
    echo ""
    echo -e "${BLUE}Rinnovo certificato client: $cert_name${NC}"
    
    # Verifica chiave esistente
    local key_path="/etc/easy-rsa/client/$cert_name.key"
    if [ ! -f "$key_path" ]; then
        echo -e "${RED}✗ Errore: Chiave privata non trovata: $key_path${NC}"
        return 1
    fi
    
    # Cambia directory
    cd /etc/easy-rsa || {
        echo -e "${RED}✗ Errore: Impossibile accedere alla directory /etc/easy-rsa${NC}"
        return 1
    }
    
    echo -e "${YELLOW}Generazione nuova richiesta certificato client...${NC}"
    
    # Pulisci eventuali file temporanei esistenti
    rm -f "/etc/easy-rsa/pki/reqs/$cert_name.req" 2>/dev/null
    rm -f "/etc/easy-rsa/pki/issued/$cert_name.crt" 2>/dev/null
    rm -f "/etc/easy-rsa/pki/private/$cert_name.key" 2>/dev/null
    
    # Crea file temporaneo per input automatico
    local temp_input=$(mktemp)
    cat > "$temp_input" << 'EOF'



EOF
    
    # Imposta variabili per EasyRSA
    export EASYRSA_REQ_CN="$cert_name"
    export EASYRSA_BATCH="1"
    
    # Genera richiesta client
    if ./easyrsa gen-req "$cert_name" nopass < "$temp_input"; then
        echo -e "${GREEN}✓ Richiesta client generata${NC}"
    else
        echo -e "${RED}✗ Errore durante la generazione della richiesta client${NC}"
        rm -f "$temp_input"
        cd - > /dev/null
        return 1
    fi
    
    # Pulisci file temporaneo
    rm -f "$temp_input"
    
    # Sostituisci con la chiave originale
    if cp "$key_path" "/etc/easy-rsa/pki/private/$cert_name.key"; then
        echo -e "${GREEN}✓ Chiave privata originale ripristinata${NC}"
    else
        echo -e "${RED}✗ Errore nel ripristino della chiave privata${NC}"
        cd - > /dev/null
        return 1
    fi
    
    echo ""
    echo -e "${YELLOW}Firma del nuovo certificato client...${NC}"
    
    # Firma come certificato client
    if ./easyrsa sign-req client "$cert_name"; then
        echo ""
        echo -e "${GREEN}✓ Nuovo certificato client generato!${NC}"
        
        # Sposta il nuovo certificato
        if mv "/etc/easy-rsa/pki/issued/$cert_name.crt" "$cert_path"; then
            echo -e "${GREEN}✓ Certificato client rinnovato: $cert_path${NC}"
        else
            echo -e "${RED}✗ Errore nel posizionamento del nuovo certificato${NC}"
            cd - > /dev/null
            return 1
        fi
        
        # Pulizia
        rm -f "/etc/easy-rsa/pki/reqs/$cert_name.req" 2>/dev/null
        
        echo ""
        echo -e "${GREEN}✓ Rinnovo certificato client completato!${NC}"
        
    else
        echo ""
        echo -e "${RED}✗ Errore durante la firma del certificato client${NC}"
        cd - > /dev/null
        return 1
    fi
    
    cd - > /dev/null
}

# Funzione per trovare un certificato per numero
find_certificate_by_number() {
    local target_number="$1"
    local -n path_ref=$2
    local -n type_ref=$3
    local current_number=0
    
    # Cerca nei certificati server (nelle directory individuali)
    if [ -d "/etc/easy-rsa" ]; then
        while IFS= read -r -d '' server_dir; do
            local dir_name=$(basename "$server_dir")
            # Salta le directory standard
            if [[ "$dir_name" != "pki" && "$dir_name" != "client" && "$dir_name" != "signed-certificates" && "$dir_name" != "pending-requests" && "$dir_name" != "processed-requests" ]]; then
                # Cerca file .crt nella directory
                while IFS= read -r -d '' file; do
                    current_number=$((current_number + 1))
                    if [ "$current_number" -eq "$target_number" ]; then
                        path_ref="$file"
                        type_ref="server"
                        return 0
                    fi
                done < <(find "$server_dir" -maxdepth 1 -name "*.crt" -type f -print0 2>/dev/null | sort -z)
            fi
        done < <(find "/etc/easy-rsa" -maxdepth 1 -type d -print0 2>/dev/null)
    fi
    
    # Cerca nei certificati client
    local client_dir="/etc/easy-rsa/client"
    if [ -d "$client_dir" ]; then
        while IFS= read -r -d '' file; do
            current_number=$((current_number + 1))
            if [ "$current_number" -eq "$target_number" ]; then
                path_ref="$file"
                type_ref="client"
                return 0
            fi
        done < <(find "$client_dir" -maxdepth 1 -name "*.crt" -type f -print0 2>/dev/null | sort -z)
    fi
    
    # Cerca nei certificati da richieste
    local signed_dir="/etc/easy-rsa/signed-certificates"
    if [ -d "$signed_dir" ]; then
        while IFS= read -r -d '' file; do
            current_number=$((current_number + 1))
            if [ "$current_number" -eq "$target_number" ]; then
                path_ref="$file"
                type_ref="signed"
                return 0
            fi
        done < <(find "$signed_dir" -maxdepth 1 -name "*.crt" -type f -print0 2>/dev/null | sort -z)
    fi
    
    # Non trovato
    path_ref=""
    type_ref=""
    return 1
}