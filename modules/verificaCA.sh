#!bin/bash

# Variabile per tracciare la presenza della CA
CAyes=""


# Funzione per verificare la presenza dei file CA
check_ca_files() {
    echo -e "${YELLOW}Verifica presenza file CA...${NC}"
    echo ""
    
    # Possibili percorsi dove cercare i file CA
    CA_PATHS=(
        "/etc/easy-rsa/pki/ca.crt"
    )
    
    KEY_PATHS=(
        "/etc/easy-rsa/pki/private/ca.key"
    )
    
    CA_FILE=""
    KEY_FILE=""
    
    # Cerca il file ca.crt
    for path in "${CA_PATHS[@]}"; do
        if [ -f "$path" ]; then
            CA_FILE="$path"
            echo -e "${GREEN}✓ CA Certificate trovato:${NC} $path"
            break
        fi
    done
    
    # Cerca il file ca.key
    for path in "${KEY_PATHS[@]}"; do
        if [ -f "$path" ]; then
            KEY_FILE="$path"
            echo -e "${GREEN}✓ CA Private Key trovata:${NC} $path"
            break
        fi
    done
    
    # Verifica i risultati
    if [ -n "$CA_FILE" ] && [ -n "$KEY_FILE" ]; then
        CAyes="true"
        echo -e "${GREEN}✓ Tutti i file CA necessari sono presenti${NC}"
    elif [ -n "$CA_FILE" ] && [ -z "$KEY_FILE" ]; then
        CAyes="false"
        echo -e "${YELLOW}⚠ CA Certificate presente ma manca la Private Key${NC}"
    elif [ -z "$CA_FILE" ] && [ -n "$KEY_FILE" ]; then
        CAyes="false"
        echo -e "${YELLOW}⚠ CA Private Key presente ma manca il Certificate${NC}"
    else
        CAyes="false"
        echo -e "${RED}✗ Nessun file CA trovato${NC}"
    fi
    
    echo ""
    #echo -e "Variabile CAyes = ${GREEN}$CAyes${NC}"
    echo ""
}

print_ca_data() {
    echo -e "${BLUE}Verifica dati CA...${NC}"
    echo ""
            
    # Controlla la variabile CAyes
    if [ "$CAyes" = "false" ] || [ -z "$CAyes" ]; then
         echo -e "${RED}✗ CA non presente o incompleta${NC}"
        echo -e "${YELLOW}È necessario creare una nuova CA prima di procedere.${NC}"
        echo -e "${YELLOW}Seleziona l'opzione 2 dal menu principale per generare una nuova CA.${NC}"
        echo ""
    elif [ "$CAyes" = "true" ]; then
        echo -e "${GREEN}✓ CA presente e valida${NC}"
        echo -e "${BLUE}Dettagli del certificato CA:${NC}"
        echo ""
        echo "----------------------------------------"
        openssl x509 -in /etc/easy-rsa/pki/ca.crt -text -noout
        echo "----------------------------------------"
    else
        echo -e "${RED}✗ Errore nella verifica dello stato CA${NC}"
    fi
}