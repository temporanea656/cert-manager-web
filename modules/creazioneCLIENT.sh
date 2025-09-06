#!/bin/bash

# Funzione per generare un certificato client
generate_client_certificate() {
    # Raccolta informazioni per il certificato client
    echo -e "${BLUE}Inserisci le informazioni per il certificato client:${NC}"
    echo ""

    # Nome del certificato
    local cert_name
    while true; do
        read -p "Nome del client (es: mario-rossi, admin-user): " cert_name
        if [ -n "$cert_name" ]; then
            # Rimuovi caratteri non validi e converti in minuscolo
            cert_name=$(echo "$cert_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]//g')
            if [ -n "$cert_name" ]; then
                break
            fi
        fi
        echo -e "${RED}Nome non valido. Usa solo lettere, numeri, punti, underscore e trattini.${NC}"
    done

    # Email del client
    local client_email
    echo ""
    echo -e "${YELLOW}Inserisci l'email del client (opzionale, premi INVIO per saltare):${NC}"
    while true; do
        read -p "Email client: " client_email
        if [ -z "$client_email" ]; then
            break
        elif [[ $client_email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        fi
        echo -e "${RED}Formato email non valido. Usa il formato nome@dominio.com${NC}"
    done
    
    # Mostra riepilogo
    echo ""
    echo -e "${BLUE}===== RIEPILOGO CERTIFICATO CLIENT =====${NC}"
    echo -e "Nome certificato: ${GREEN}$cert_name${NC}"
    echo -e "Email client: ${GREEN}${client_email:-"Non specificata"}${NC}"
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
    create_client_certificate "$cert_name" "$client_email"
}    

# Funzione per creare effettivamente il certificato client
create_client_certificate() {
    local cert_name="$1"
    local client_email="$2"
    
    echo ""
    echo -e "${BLUE}Creazione certificato client...${NC}"
    
    # Cambia directory
    cd /etc/easy-rsa || {
        echo -e "${RED}✗ Errore: Impossibile accedere alla directory /etc/easy-rsa${NC}"
        return 1
    }
    
    echo -e "${YELLOW}Generazione richiesta certificato per: $cert_name${NC}"
    
    # Imposta il Common Name per il client
    local common_name="$cert_name"
    if [ -n "$client_email" ]; then
        common_name="$cert_name ($client_email)"
    fi
    
    # Genera la richiesta di certificato (senza password)
    EASYRSA_REQ_CN="$common_name" \
    EASYRSA_BATCH="1" \
    ./easyrsa gen-req "$cert_name" nopass
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Errore durante la generazione della richiesta certificato!${NC}"
        cd - > /dev/null
        return 1
    fi
    
    echo ""
    echo -e "${YELLOW}Firma del certificato con la CA...${NC}"
    
     # Firma il certificato come client certificate
    ./easyrsa sign-req client "$cert_name"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Certificato client generato con successo!${NC}"
        
        # Crea la directory client se non esiste
        local client_dir="/etc/easy-rsa/client"
        echo ""
        echo -e "${BLUE}Preparazione directory client: $client_dir${NC}"
        
        if mkdir -p "$client_dir"; then
            echo -e "${GREEN}✓ Directory pronta: $client_dir${NC}"
            
            # Sposta i file dalla struttura PKI alla directory client
            local files_copied=0
            
            # Sposta il certificato
            if [ -f "/etc/easy-rsa/pki/issued/$cert_name.crt" ]; then
                cp "/etc/easy-rsa/pki/issued/$cert_name.crt" "$client_dir/$cert_name.crt"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ Certificato copiato: $client_dir/$cert_name.crt${NC}"
                    files_copied=$((files_copied + 1))
                    # Rimuovi dall'originale dopo la copia
                    rm "/etc/easy-rsa/pki/issued/$cert_name.crt"
                else
                    echo -e "${RED}✗ Errore nella copia del certificato${NC}"
                fi
            fi
            
            # Sposta la chiave privata
            if [ -f "/etc/easy-rsa/pki/private/$cert_name.key" ]; then
                cp "/etc/easy-rsa/pki/private/$cert_name.key" "$client_dir/$cert_name.key"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ Chiave privata copiata: $client_dir/$cert_name.key${NC}"
                    # Imposta permessi sicuri per la chiave privata
                    chmod 600 "$client_dir/$cert_name.key"
                    echo -e "${YELLOW}✓ Permessi chiave privata impostati (600)${NC}"
                    files_copied=$((files_copied + 1))
                    # Rimuovi dall'originale dopo la copia
                    rm "/etc/easy-rsa/pki/private/$cert_name.key"
                else
                    echo -e "${RED}✗ Errore nella copia della chiave privata${NC}"
                fi
            fi
            
            # Sposta la richiesta di certificato
            if [ -f "/etc/easy-rsa/pki/reqs/$cert_name.req" ]; then
                cp "/etc/easy-rsa/pki/reqs/$cert_name.req" "$client_dir/$cert_name.req"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ Richiesta copiata: $client_dir/$cert_name.req${NC}"
                    files_copied=$((files_copied + 1))
                    # Rimuovi dall'originale dopo la copia
                    rm "/etc/easy-rsa/pki/reqs/$cert_name.req"
                else
                    echo -e "${RED}✗ Errore nella copia della richiesta${NC}"
                fi
            fi

            # Crea un file README specifico per questo client
            cat > "$client_dir/$cert_name-README.txt" << EOF
Certificato Client: $cert_name
Generato il: $(date)
Email: ${client_email:-"Non specificata"}

File per questo client:
- $cert_name.crt: Certificato del client
- $cert_name.key: Chiave privata del client (permessi 600)
- $cert_name.req: Richiesta di certificato originale

File condivisi:
- ca.crt: Certificato della Certificate Authority (necessario per la verifica)

Per utilizzare il certificato client:
1. Copiare $cert_name.crt e $cert_name.key sul dispositivo client
2. Configurare l'applicazione client per utilizzare questi file
3. Assicurarsi che il client abbia accesso al file ca.crt per la verifica

ATTENZIONE: La chiave privata ($cert_name.key) deve essere mantenuta segreta!
EOF
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ File README creato: $client_dir/$cert_name-README.txt${NC}"
                files_copied=$((files_copied + 1))
            fi
            
            echo ""
            echo -e "${BLUE}===== FILE NELLA DIRECTORY CLIENT =====${NC}"
            echo -e "Directory: ${GREEN}$client_dir${NC}"
            echo -e "Certificato: ${GREEN}$client_dir/$cert_name.crt${NC}"
            echo -e "Chiave privata: ${GREEN}$client_dir/$cert_name.key${NC}"
            echo -e "Richiesta: ${GREEN}$client_dir/$cert_name.req${NC}"
            echo -e "CA Certificate: ${GREEN}$client_dir/ca.crt${NC}"
            echo -e "Documentazione: ${GREEN}$client_dir/$cert_name-README.txt${NC}"
            echo ""
            echo -e "${GREEN}Totale file gestiti: $files_copied${NC}"
            
        else
            echo -e "${RED}✗ Errore nella creazione della directory $client_dir${NC}"
            echo -e "${YELLOW}I file rimangono nella struttura PKI standard.${NC}"
        fi
        
        echo ""
        echo -e "${BLUE}===== INFORMAZIONI CERTIFICATO CLIENT =====${NC}"
        if [ -f "$client_dir/$cert_name.crt" ]; then
            openssl x509 -in "$client_dir/$cert_name.crt" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:|Email:)" | sed 's/^[ \t]*//'
        elif [ -f "/etc/easy-rsa/pki/issued/$cert_name.crt" ]; then
            openssl x509 -in "/etc/easy-rsa/pki/issued/$cert_name.crt" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:|Email:)" | sed 's/^[ \t]*//'
        fi
        
        echo ""
        echo -e "${GREEN}Il certificato client è pronto per l'uso!${NC}"
        echo -e "${YELLOW}RICORDA: Mantieni la chiave privata ($cert_name.key) al sicuro e non condividerla mai.${NC}"
    else
        echo ""
        echo -e "${RED}âœ— Errore durante la firma del certificato!${NC}"
        echo -e "${YELLOW}Controlla i messaggi di errore sopra per maggiori dettagli.${NC}"
        cd - > /dev/null
        return 1
    fi

    # Torna alla directory originale
    cd - > /dev/null
}