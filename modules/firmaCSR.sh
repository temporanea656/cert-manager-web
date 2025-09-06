#!/bin/bash

# Path assoluti per le directory
BASE_DIR="/etc/easy-rsa"
PENDING_DIR="/etc/easy-rsa/pending-requests"
SIGNED_DIR="/etc/easy-rsa/signed-certificates"
PROCESSED_DIR="/etc/easy-rsa/processed-requests"
PKI_DIR="/etc/easy-rsa/pki"

# Funzione principale per gestire le richieste certificate
process_pending_requests() {
    echo -e "${BLUE}===== RICHIESTE CERTIFICATE IN SOSPESO =====${NC}"
    echo ""
    
    # Crea le directory se non esistono
    create_request_directories
    
    # Cerca file CSR nella directory pending
    local csr_files=()
    if [ -d "$PENDING_DIR" ]; then
        while IFS= read -r -d '' file; do
            csr_files+=("$(basename "$file")")
        done < <(find "$PENDING_DIR" -name "*.csr" -type f -print0)
    fi
    
    # Verifica se ci sono richieste
    if [ ${#csr_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}Nessuna richiesta da processare.${NC}"
        echo -e "${YELLOW}La directory $PENDING_DIR è vuota.${NC}"
        echo ""
        echo -e "${BLUE}Per aggiungere una richiesta, copia il file .csr in:${NC}"
        echo -e "${GREEN}$PENDING_DIR${NC}"
        return 0
    fi
    
    # Mostra menu con i file trovati
    echo "Richieste trovate:"
    echo ""
    for i in "${!csr_files[@]}"; do
        echo "[$((i+1))] ${csr_files[i]}"
    done
    echo "[0] Torna al menu principale"
    echo ""
    
    # Richiedi selezione
    local choice
    while true; do
        read -p "Inserisci la tua scelta [0-${#csr_files[@]}]: " choice
        
        if [ "$choice" = "0" ]; then
            echo -e "${GREEN}Ritorno al menu principale.${NC}"
            return 0
        elif [ "$choice" -ge 1 ] && [ "$choice" -le "${#csr_files[@]}" ] 2>/dev/null; then
            local selected_file="${csr_files[$((choice-1))]}"
            process_single_request "$selected_file"
            return 0
        else
            echo -e "${RED}Scelta non valida. Riprova.${NC}"
        fi
    done
}

# Funzione per creare le directory necessarie
create_request_directories() {
    local dirs=("$PENDING_DIR" "$SIGNED_DIR" "$PROCESSED_DIR")
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            if mkdir -p "$dir"; then
                echo -e "${GREEN}✓ Directory creata: $dir${NC}"
            else
                echo -e "${RED}✗ Errore nella creazione di: $dir${NC}"
            fi
        fi
    done
    echo ""
}

# Funzione per processare una singola richiesta
process_single_request() {
    local csr_filename="$1"
    local csr_path="$PENDING_DIR/$csr_filename"
    
    echo -e "${BLUE}===== DETTAGLI RICHIESTA CERTIFICATO =====${NC}"
    echo -e "File: ${GREEN}$csr_filename${NC}"
    echo ""
    
    # Verifica che il file esista
    if [ ! -f "$csr_path" ]; then
        echo -e "${RED}✗ Errore: File non trovato: $csr_path${NC}"
        return 1
    fi
    
    # Estrai e mostra dettagli essenziali
    show_csr_details "$csr_path"
    
    # Analizza il tipo di certificato suggerito
    local suggested_type
    local reason
    analyze_csr_type "$csr_path" suggested_type reason
    
    echo ""
    echo -e "${BLUE}Analisi automatica:${NC}"
    echo -e "Tipo suggerito: ${GREEN}${suggested_type^^}${NC} ($reason)"
    echo ""
    
    # Richiedi conferma all'utente
    echo "Vuoi approvare questa richiesta?"
    echo "[1] Sì, approva come ${suggested_type}"
    if [ "$suggested_type" = "server" ]; then
        echo "[2] No, approva come client"
    else
        echo "[2] No, approva come server"
    fi
    echo "[3] No, annulla"
    echo ""
    
    local user_choice
    while true; do
        read -p "Scelta: " user_choice
        case $user_choice in
            [1])
                sign_certificate "$csr_path" "$csr_filename" "$suggested_type"
                return 0
                ;;
            [2])
                local opposite_type
                if [ "$suggested_type" = "server" ]; then
                    opposite_type="client"
                else
                    opposite_type="server"
                fi
                sign_certificate "$csr_path" "$csr_filename" "$opposite_type"
                return 0
                ;;
            [3])
                echo ""
                echo -e "${YELLOW}Operazione annullata. Richiesta non processata.${NC}"
                return 0
                ;;
            *)
                echo -e "${RED}Risposta non valida. Inserisci 1, 2 o 3.${NC}"
                ;;
        esac
    done
}

# Funzione per mostrare dettagli essenziali della CSR
show_csr_details() {
    local csr_path="$1"
    
    # Estrai informazioni con OpenSSL
    local csr_content
    csr_content=$(openssl req -in "$csr_path" -text -noout 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Errore nella lettura della CSR${NC}"
        return 1
    fi
    
    # Estrai Subject
    local subject
    subject=$(openssl req -in "$csr_path" -subject -noout 2>/dev/null | sed 's/subject=//')
    echo -e "Subject: ${GREEN}$subject${NC}"
    
    # Estrai SAN (DNS names e IP addresses)
    local san_dns
    local san_ip
    san_dns=$(echo "$csr_content" | grep -A1 "DNS:" | grep "DNS:" | sed 's/.*DNS://g' | sed 's/, IP Address:.*//g' | tr ',' '\n' | sed 's/^[[:space:]]*//' | tr '\n' ', ' | sed 's/, $//')
    san_ip=$(echo "$csr_content" | grep "IP Address:" | sed 's/.*IP Address://g' | sed 's/, DNS:.*//g' | tr ',' '\n' | sed 's/^[[:space:]]*//' | tr '\n' ', ' | sed 's/, $//')
    
    if [ -n "$san_dns" ]; then
        echo -e "DNS Names: ${GREEN}$san_dns${NC}"
    fi
    
    if [ -n "$san_ip" ]; then
        echo -e "IP Addresses: ${GREEN}$san_ip${NC}"
    fi
    
    # Estrai informazioni sulla chiave
    local key_info
    key_info=$(echo "$csr_content" | grep "Public Key Algorithm\|Public-Key:" | head -2 | tr '\n' ' ' | sed 's/^[[:space:]]*//')
    if [ -n "$key_info" ]; then
        echo -e "Key: ${GREEN}$key_info${NC}"
    fi
    
    # Data di creazione del file
    local file_date
    if command -v stat >/dev/null 2>&1; then
        file_date=$(stat -c %y "$csr_path" 2>/dev/null | cut -d'.' -f1)
        if [ -n "$file_date" ]; then
            echo -e "Creato: ${GREEN}$file_date${NC}"
        fi
    fi
}

# Funzione per analizzare il tipo di certificato dalla CSR
analyze_csr_type() {
    local csr_path="$1"
    local -n type_ref=$2
    local -n reason_ref=$3
    
    # Estrai contenuto della CSR
    local csr_content
    csr_content=$(openssl req -in "$csr_path" -text -noout 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        type_ref="server"
        reason_ref="Errore nella lettura della CSR"
        return 1
    fi
    
    # Cerca SAN con DNS o IP
    if echo "$csr_content" | grep -q "DNS:\|IP Address:"; then
        type_ref="server"
        reason_ref="Trovati DNS names o IP addresses in SAN"
    
    # Cerca email nel subject
    elif echo "$csr_content" | grep -q "emailAddress=\|Email="; then
        type_ref="client"
        reason_ref="Trovata email address nel subject"
    
    # Default
    else
        type_ref="server"
        reason_ref="Nessun indicatore specifico trovato"
    fi
}

# Funzione per firmare il certificato
sign_certificate() {
    local csr_path="$1"
    local csr_filename="$2"
    local cert_type="$3"
    
    echo ""
    echo -e "${BLUE}Firma del certificato come ${cert_type^^}...${NC}"
    
    # Estrai nome base del file (senza estensione)
    local cert_name
    cert_name=$(basename "$csr_filename" .csr)
    
    # Cambia nella directory easy-rsa
    cd "$BASE_DIR" || {
        echo -e "${RED}✗ Errore: Impossibile accedere alla directory $BASE_DIR${NC}"
        return 1
    }
    
    echo -e "${YELLOW}Importazione della richiesta certificato...${NC}"
    
    # Importa la CSR nel sistema PKI
    if ! ./easyrsa import-req "$csr_path" "$cert_name"; then
        echo -e "${RED}✗ Errore durante l'importazione della richiesta${NC}"
        cd - > /dev/null
        return 1
    fi
    
    echo ""
    echo -e "${YELLOW}Firma del certificato...${NC}"
    
    # Firma la richiesta
    if ./easyrsa sign-req "$cert_type" "$cert_name"; then
        echo ""
        echo -e "${GREEN}✓ Certificato firmato con successo!${NC}"
        
        # Gestisci i file in base al tipo di certificato
        if [ "$cert_type" = "server" ]; then
            manage_server_certificate "$cert_name" "$csr_filename"
        else
            manage_client_certificate "$cert_name" "$csr_filename"
        fi
        
        # IMPORTANTE: Rimuovi la richiesta dalla directory PKI
        local pki_req="$PKI_DIR/reqs/$cert_name.req"
        if [ -f "$pki_req" ]; then
            if rm "$pki_req"; then
                echo -e "${GREEN}✓ Richiesta rimossa da PKI: $pki_req${NC}"
            else
                echo -e "${YELLOW}⚠ Impossibile rimuovere: $pki_req${NC}"
            fi
        fi
        
        # Sposta la CSR originale nell'archivio
        if mv "$csr_path" "$PROCESSED_DIR/$csr_filename"; then
            echo -e "${GREEN}✓ Richiesta originale archiviata in: $PROCESSED_DIR/$csr_filename${NC}"
        else
            echo -e "${YELLOW}⚠ Impossibile archiviare la richiesta originale${NC}"
        fi
        
    else
        echo ""
        echo -e "${RED}✗ Errore durante la firma del certificato${NC}"
        
        # Rimuovi la richiesta parzialmente importata in caso di errore
        local pki_req="$PKI_DIR/reqs/$cert_name.req"
        if [ -f "$pki_req" ]; then
            rm "$pki_req" 2>/dev/null
            echo -e "${YELLOW}⚠ Richiesta parziale rimossa da PKI${NC}"
        fi
        
        cd - > /dev/null
        return 1
    fi
    
    # Torna alla directory originale
    cd - > /dev/null
}

# Funzione per gestire i certificati server
manage_server_certificate() {
    local cert_name="$1"
    local original_csr="$2"
    
    local server_dir="$BASE_DIR/$cert_name"
    
    echo ""
    echo -e "${BLUE}Creazione directory server: $server_dir${NC}"
    
    if mkdir -p "$server_dir"; then
        echo -e "${GREEN}✓ Directory creata: $server_dir${NC}"
        
        # Sposta certificato
        local pki_cert="$PKI_DIR/issued/$cert_name.crt"
        if [ -f "$pki_cert" ]; then
            if mv "$pki_cert" "$server_dir/$cert_name.crt"; then
                echo -e "${GREEN}✓ Certificato spostato in: $server_dir/$cert_name.crt${NC}"
            fi
        fi
        
        # Copia CA certificate
        if [ -f "$PKI_DIR/ca.crt" ]; then
            if cp "$PKI_DIR/ca.crt" "$server_dir/ca.crt"; then
                echo -e "${GREEN}✓ CA certificate copiato in: $server_dir/ca.crt${NC}"
            fi
        fi
        
        # Crea README
        create_server_readme "$cert_name" "$server_dir" "$original_csr"
        
        echo ""
        echo -e "${BLUE}===== CERTIFICATO SERVER PRONTO =====${NC}"
        echo -e "Directory: ${GREEN}$server_dir${NC}"
        echo -e "Certificato: ${GREEN}$server_dir/$cert_name.crt${NC}"
        echo -e "CA Certificate: ${GREEN}$server_dir/ca.crt${NC}"
        
    else
        echo -e "${RED}✗ Errore nella creazione della directory server${NC}"
    fi
}

# Funzione per gestire i certificati client
manage_client_certificate() {
    local cert_name="$1"
    local original_csr="$2"
    
    local client_dir="$BASE_DIR/client"
    
    echo ""
    echo -e "${BLUE}Preparazione directory client: $client_dir${NC}"
    
    if mkdir -p "$client_dir"; then
        echo -e "${GREEN}✓ Directory pronta: $client_dir${NC}"
        
        # Sposta certificato
        local pki_cert="$PKI_DIR/issued/$cert_name.crt"
        if [ -f "$pki_cert" ]; then
            if mv "$pki_cert" "$client_dir/$cert_name.crt"; then
                echo -e "${GREEN}✓ Certificato spostato in: $client_dir/$cert_name.crt${NC}"
            fi
        fi
        
        # Crea README per questo client
        create_client_readme "$cert_name" "$client_dir" "$original_csr"
        
        echo ""
        echo -e "${BLUE}===== CERTIFICATO CLIENT PRONTO =====${NC}"
        echo -e "Directory: ${GREEN}$client_dir${NC}"
        echo -e "Certificato: ${GREEN}$client_dir/$cert_name.crt${NC}"
        echo -e "CA Certificate: ${GREEN}$client_dir/ca.crt${NC}"
        
    else
        echo -e "${RED}✗ Errore nella creazione della directory client${NC}"
    fi
}

# Funzione per creare README per certificato server
create_server_readme() {
    local cert_name="$1"
    local server_dir="$2"
    local original_csr="$3"
    
    cat > "$server_dir/README.txt" << EOF
Certificato SERVER: $cert_name
Generato il: $(date)
Richiesta originale: $original_csr

File per questo server:
- $cert_name.crt: Certificato del server firmato dalla CA
- ca.crt: Certificato della Certificate Authority

Per utilizzare il certificato:
1. Configurare il server per usare $cert_name.crt
2. La chiave privata è rimasta sul sistema che ha generato la richiesta
3. Distribuire ca.crt ai client per la verifica

NOTA: La chiave privata NON è inclusa perché è rimasta 
sul sistema che ha generato la richiesta originale.
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ File README creato: $server_dir/README.txt${NC}"
    fi
}

# Funzione per creare README per certificato client
create_client_readme() {
    local cert_name="$1"
    local client_dir="$2"
    local original_csr="$3"
    
    cat > "$client_dir/$cert_name-README.txt" << EOF
Certificato CLIENT: $cert_name
Generato il: $(date)
Richiesta originale: $original_csr

File per questo client:
- $cert_name.crt: Certificato del client firmato dalla CA
- ca.crt: Certificato della Certificate Authority (condiviso)

Per utilizzare il certificato:
1. Copiare $cert_name.crt sul dispositivo client
2. La chiave privata è rimasta sul sistema che ha generato la richiesta
3. Configurare l'applicazione client per utilizzare il certificato
4. Assicurarsi che il client abbia accesso al file ca.crt per la verifica

NOTA: La chiave privata NON è inclusa perché è rimasta 
sul sistema che ha generato la richiesta originale.
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ File README creato: $client_dir/$cert_name-README.txt${NC}"
    fi
}