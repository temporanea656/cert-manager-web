#!/bin/bash

# Funzione principale per listare tutti i certificati con stato validità
list_certificates() {
    echo -e "${BLUE}===== LISTA CERTIFICATI =====${NC}"
    echo ""
    
    # Preparare il contenuto per il pager
    local temp_output=$(mktemp)
    
    # Header del file temporaneo
    echo "===== LISTA CERTIFICATI =====" > "$temp_output"
    echo "" >> "$temp_output"
    
    # Contatori per ogni tipo
    local server_count=0
    local client_count=0
    local signed_count=0
    local global_count=0
    local expired_count=0
    local expiring_count=0
    
    # Aggiungi informazioni sulla CA se presente
    if [ "$CAyes" = "true" ]; then
        echo "" >> "$temp_output"
        echo -e "${GREEN}✓ Certificate Authority presente${NC}" >> "$temp_output"
        if [ -f "/etc/easy-rsa/pki/ca.crt" ]; then
            local ca_subject=$(openssl x509 -in "/etc/easy-rsa/pki/ca.crt" -subject -noout 2>/dev/null | sed 's/subject=//')
            echo -e "CA Subject: ${YELLOW}$ca_subject${NC}" >> "$temp_output"
            
            # Controlla anche la scadenza della CA
            local ca_status=$(get_certificate_status "/etc/easy-rsa/pki/ca.crt")
            echo -e "CA Status: $ca_status" >> "$temp_output"
        fi
    else
        echo "" >> "$temp_output"
        echo -e "${RED}✗ Certificate Authority non presente${NC}" >> "$temp_output"
    fi
    echo "" >> "$temp_output"

    # Lista certificati server
    echo -e "${GREEN}CERTIFICATI SERVER${NC}" >> "$temp_output"
    echo "==================" >> "$temp_output"
    
    # Cerca certificati nelle directory dei singoli server
    if [ -d "/etc/easy-rsa" ]; then
        # Cerca directory che contengono certificati (escludendo le directory standard)
        while IFS= read -r -d '' server_dir; do
            local dir_name=$(basename "$server_dir")
            # Salta le directory standard
            if [[ "$dir_name" != "pki" && "$dir_name" != "client" && "$dir_name" != "signed-certificates" && "$dir_name" != "pending-requests" && "$dir_name" != "processed-requests" ]]; then
                # Cerca file .crt nella directory
                while IFS= read -r -d '' file; do
                    global_count=$((global_count + 1))
                    server_count=$((server_count + 1))
                    local filename=$(basename "$file")
                    local status_info=$(get_certificate_status "$file")
                    echo "$global_count. $dir_name/$filename $status_info" >> "$temp_output"
                    
                    # Conta certificati in scadenza/scaduti per statistiche
                    if [[ "$status_info" == *"SCADUTO"* ]]; then
                        expired_count=$((expired_count + 1))
                    elif [[ "$status_info" == *"⚠"* ]]; then
                        expiring_count=$((expiring_count + 1))
                    fi
                done < <(find "$server_dir" -maxdepth 1 -name "*.crt" -type f -print0 2>/dev/null | sort -z)
            fi
        done < <(find "/etc/easy-rsa" -maxdepth 1 -type d -print0 2>/dev/null)
    fi
    
    if [ $server_count -eq 0 ]; then
        echo -e "${YELLOW}Nessun certificato server trovato${NC}" >> "$temp_output"
    fi
    echo -e "${GREEN}Totale certificati server: $server_count${NC}" >> "$temp_output"
    echo "" >> "$temp_output"
    
    # Lista certificati client
    echo -e "${GREEN}CERTIFICATI CLIENT${NC}" >> "$temp_output"
    echo "==================" >> "$temp_output"
    
    local client_dir="/etc/easy-rsa/client"
    if [ -d "$client_dir" ]; then
        while IFS= read -r -d '' file; do
            global_count=$((global_count + 1))
            client_count=$((client_count + 1))
            local filename=$(basename "$file")
            local status_info=$(get_certificate_status "$file")
            echo "$global_count. $filename $status_info" >> "$temp_output"
            
            # Conta certificati in scadenza/scaduti per statistiche
            if [[ "$status_info" == *"SCADUTO"* ]]; then
                expired_count=$((expired_count + 1))
            elif [[ "$status_info" == *"⚠"* ]]; then
                expiring_count=$((expiring_count + 1))
            fi
        done < <(find "$client_dir" -maxdepth 1 -name "*.crt" -type f -print0 2>/dev/null | sort -z)
    fi
    
    if [ $client_count -eq 0 ]; then
        echo -e "${YELLOW}Nessun certificato client trovato${NC}" >> "$temp_output"
    fi
    echo -e "${GREEN}Totale certificati client: $client_count${NC}" >> "$temp_output"
    echo "" >> "$temp_output"
    
    # Lista certificati da richieste
    echo -e "${GREEN}CERTIFICATI DA RICHIESTE${NC}" >> "$temp_output"
    echo "=======================" >> "$temp_output"
    
    local signed_dir="/etc/easy-rsa/signed-certificates"
    if [ -d "$signed_dir" ]; then
        while IFS= read -r -d '' file; do
            global_count=$((global_count + 1))
            signed_count=$((signed_count + 1))
            local filename=$(basename "$file")
            local status_info=$(get_certificate_status "$file")
            echo "$global_count. $filename $status_info" >> "$temp_output"
            
            # Conta certificati in scadenza/scaduti per statistiche
            if [[ "$status_info" == *"SCADUTO"* ]]; then
                expired_count=$((expired_count + 1))
            elif [[ "$status_info" == *"⚠"* ]]; then
                expiring_count=$((expiring_count + 1))
            fi
        done < <(find "$signed_dir" -maxdepth 1 -name "*.crt" -type f -print0 2>/dev/null | sort -z)
    fi
    
    if [ $signed_count -eq 0 ]; then
        echo -e "${YELLOW}Nessun certificato da richieste trovato${NC}" >> "$temp_output"
    fi
    echo -e "${GREEN}Totale certificati da richieste: $signed_count${NC}" >> "$temp_output"
    echo "" >> "$temp_output"
    
    # Riepilogo finale con allarmi
    echo -e "${BLUE}===== RIEPILOGO GENERALE =====${NC}" >> "$temp_output"
    echo "" >> "$temp_output"
    echo "Certificati Server: $server_count" >> "$temp_output"
    echo "Certificati Client: $client_count" >> "$temp_output"
    echo "Certificati da Richieste: $signed_count" >> "$temp_output"
    echo "----------------------------------------" >> "$temp_output"
    echo -e "${GREEN}Totale certificati: $global_count${NC}" >> "$temp_output"
    
    # Allarmi per scadenze
    if [ $expired_count -gt 0 ]; then
        echo -e "${RED}⚠ ATTENZIONE: $expired_count certificati SCADUTI${NC}" >> "$temp_output"
    fi
    if [ $expiring_count -gt 0 ]; then
        echo -e "${YELLOW}⚠ AVVISO: $expiring_count certificati in SCADENZA${NC}" >> "$temp_output"
    fi

    # Usa more se il contenuto è troppo lungo, altrimenti stampa direttamente
    local line_count=$(wc -l < "$temp_output")
    if [ "$line_count" -gt 20 ]; then
        echo -e "${YELLOW}Lista lunga, usando 'more' per la visualizzazione...${NC}"
        echo -e "${YELLOW}Premi SPAZIO per continuare, 'q' per uscire${NC}"
        echo ""
        more "$temp_output"
    else
        cat "$temp_output"
    fi
    
    # Pulisci il file temporaneo
    rm -f "$temp_output"
    
    # Menu azioni se ci sono certificati
    if [ $global_count -gt 0 ]; then
        show_certificate_actions_menu "$global_count" "$expired_count" "$expiring_count"
    fi
}

# Funzione per ottenere lo stato di validità di un certificato
get_certificate_status() {
    local cert_path="$1"
    
    if [ ! -f "$cert_path" ]; then
        echo -e "${RED}(✗ FILE NON TROVATO)${NC}"
        return 1
    fi
    
    # Verifica se il certificato è valido
    local current_date=$(date +%s)
    local not_after=$(openssl x509 -in "$cert_path" -noout -enddate 2>/dev/null | cut -d= -f2)
    local not_after_epoch=$(date -d "$not_after" +%s 2>/dev/null)
    
    if [ -n "$not_after_epoch" ]; then
        local days_remaining=$(( (not_after_epoch - current_date) / 86400 ))
        
        if [ $days_remaining -gt 30 ]; then
            echo -e "${GREEN}(✓ $days_remaining giorni rimanenti)${NC}"
        elif [ $days_remaining -gt 7 ]; then
            echo -e "${YELLOW}(⚠ $days_remaining giorni rimanenti)${NC}"
        elif [ $days_remaining -gt 0 ]; then
            echo -e "${RED}(⚠ SCADE TRA $days_remaining GIORNI!)${NC}"
        else
            echo -e "${RED}(✗ SCADUTO - $((days_remaining * -1)) giorni fa)${NC}"
        fi
    else
        echo -e "${YELLOW}(? Impossibile verificare validità)${NC}"
    fi
}

# Funzione per mostrare il menu azioni sui certificati
show_certificate_actions_menu() {
    local total_certs="$1"
    local expired_certs="$2"
    local expiring_certs="$3"
    
    echo ""
    echo -e "${BLUE}===== AZIONI DISPONIBILI =====${NC}"
    echo ""
    echo "1) Visualizza dettagli di un certificato specifico"
    echo "2) Rinnova un certificato"
    echo "0) Torna al menu principale"
    echo ""
    
    # Mostra avvisi se necessario
    if [ "$expired_certs" -gt 0 ] || [ "$expiring_certs" -gt 0 ]; then
        echo -e "${YELLOW}Azioni consigliate:${NC}"
        if [ "$expired_certs" -gt 0 ]; then
            echo -e "${RED}• Rinnova i $expired_certs certificati SCADUTI${NC}"
        fi
        if [ "$expiring_certs" -gt 0 ]; then
            echo -e "${YELLOW}• Considera di rinnovare i $expiring_certs certificati in SCADENZA${NC}"
        fi
        echo ""
    fi
    
    local choice
    while true; do
        read -p "Inserisci la tua scelta [0-2]: " choice
        case $choice in
            1)
                show_certificate_details "$total_certs"
                break
                ;;
            2)
                renew_certificate_menu "$total_certs"
                break
                ;;
            0)
                echo -e "${GREEN}Ritorno al menu principale.${NC}"
                return 0
                ;;
            *)
                echo -e "${RED}Scelta non valida. Riprova.${NC}"
                ;;
        esac
    done
}

# Funzione per mostrare dettagli di un certificato specifico
show_certificate_details() {
    local total_certs="$1"
    
    echo ""
    echo -e "${BLUE}Inserisci il numero del certificato da visualizzare [1-$total_certs]:${NC}"
    read -p "Numero: " cert_number
    
    if [[ "$cert_number" =~ ^[0-9]+$ ]] && [ "$cert_number" -ge 1 ] && [ "$cert_number" -le "$total_certs" ]; then
        local cert_path
        local cert_type
        if find_certificate_by_number "$cert_number" cert_path cert_type; then
            echo ""
            echo -e "${BLUE}===== DETTAGLI CERTIFICATO =====${NC}"
            echo -e "Tipo: ${GREEN}${cert_type^^}${NC}"
            echo -e "Percorso: ${GREEN}$cert_path${NC}"
            echo ""
            echo -e "${BLUE}Informazioni certificato:${NC}"
            openssl x509 -in "$cert_path" -text -noout 2>/dev/null | head -30
        else
            echo -e "${RED}✗ Certificato non trovato${NC}"
        fi
    else
        echo -e "${RED}Numero non valido${NC}"
    fi
    
    echo ""
    read -p "Premi INVIO per tornare alla lista certificati..."
    clear
    list_certificates
}

# Funzione placeholder per il rinnovo certificati
renew_certificate_menu() {
    local total_certs="$1"
    echo ""
    renew_certificate_menu
}


# Funzione per trovare un certificato per numero (da implementare completamente)
find_certificate_by_number() {
    local target_number="$1"
    local -n path_ref=$2
    local -n type_ref=$3
    local current_number=0
    
    # Placeholder - questa funzione dovrebbe essere completata
    # per ora ritorna falso
    path_ref=""
    type_ref=""
    return 1
}
