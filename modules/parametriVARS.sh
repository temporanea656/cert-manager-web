#!/bin/bash

# Funzione principale per gestire i parametri VARS
manage_vars_parameters() {
    echo -e "${BLUE}===== GESTIONE PARAMETRI VARS =====${NC}"
    echo ""
    
    local vars_file="/etc/easy-rsa/vars"
    
    # Verifica se il file vars esiste, se non esiste lo crea con valori di default
    if [ ! -f "$vars_file" ]; then
        echo -e "${YELLOW}File vars non trovato. Crea un nuovo file${NC}"
        # Blocco il richiamo alla funzione per creare il file default
        #create_default_vars_file "$vars_file"
    fi
    
    # Mostra contenuto attuale
    show_current_vars "$vars_file"
    
    # Menu opzioni
    echo ""
    echo -e "${BLUE}Opzioni disponibili:${NC}"
    echo "1) Modifica parametri"
    echo "2) Torna al menu principale"
    echo ""
    
    local choice
    while true; do
        read -p "Inserisci la tua scelta [1-2]: " choice
        case $choice in
            1)
                modify_vars_parameters "$vars_file"
                break
                ;;
            2)
                echo -e "${GREEN}Ritorno al menu principale.${NC}"
                return 0
                ;;
            *)
                echo -e "${RED}Scelta non valida. Riprova.${NC}"
                ;;
        esac
    done
}

# Funzione per mostrare i parametri VARS attuali
show_current_vars() {
    local vars_file="$1"
    
    echo -e "${BLUE}Parametri VARS attuali:${NC}"
    echo "========================"
    
    if [ -f "$vars_file" ]; then
        # Leggi e mostra i valori attuali
        local country=$(grep "EASYRSA_REQ_COUNTRY" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
        local province=$(grep "EASYRSA_REQ_PROVINCE" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
        local city=$(grep "EASYRSA_REQ_CITY" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
        local org=$(grep "EASYRSA_REQ_ORG" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
        local email=$(grep "EASYRSA_REQ_EMAIL" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
        local ou=$(grep "EASYRSA_REQ_OU" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
        local cn=$(grep "EASYRSA_REQ_CN_DEFAULT" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
        local digest=$(grep "EASYRSA_DIGEST" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
        local ca_expire=$(grep "EASYRSA_CA_EXPIRE" "$vars_file" 2>/dev/null | sed -n 's/.*[[:space:]]\([0-9]*\).*/\1/p')
        local cert_expire=$(grep "EASYRSA_CERT_EXPIRE" "$vars_file" 2>/dev/null | sed -n 's/.*[[:space:]]\([0-9]*\).*/\1/p')
        local key_size=$(grep "EASYRSA_KEY_SIZE" "$vars_file" 2>/dev/null | sed -n 's/.*[[:space:]]\([0-9]*\).*/\1/p')
        
        printf "%-20s : %s\n" "PAESE" "${country:-Non impostato}"
        printf "%-20s : %s\n" "PROVINCIA" "${province:-Non impostato}"
        printf "%-20s : %s\n" "CITTÀ" "${city:-Non impostato}"
        printf "%-20s : %s\n" "ORGANIZZAZIONE" "${org:-Non impostato}"
        printf "%-20s : %s\n" "EMAIL" "${email:-Non impostato}"
        printf "%-20s : %s\n" "UNITÀ ORG." "${ou:-Non impostato}"
        printf "%-20s : %s\n" "NOME CA" "${cn:-Non impostato}"
        printf "%-20s : %s\n" "DIGEST" "${digest:-sha512}"
        printf "%-20s : %s giorni\n" "SCADENZA CA" "${ca_expire:-3650}"
        printf "%-20s : %s giorni\n" "SCADENZA CERT" "${cert_expire:-365}"
        printf "%-20s : %s bit\n" "CHIAVE" "${key_size:-2048}"
    else
        echo -e "${RED}File vars non trovato: $vars_file${NC}"
    fi
    echo ""
}

# NON DOVREBBE SERVIRE PER CUI E' COMMENTATA, E' UNA POSSIIBLITA'
#
# Funzione per creare un file vars di default
#create_default_vars_file() {
#    local vars_file="$1"
#    
#    echo -e "${YELLOW}Creazione file vars con parametri di default...${NC}"
#    
#    cat > "$vars_file" << 'EOF'
# Easy-RSA 3 parameter settings
#
# Digest algorithm (default sha512)
#set_var EASYRSA_DIGEST "sha512"
#
# Certificate Authority settings
#set_var EASYRSA_REQ_COUNTRY "IT"
#set_var EASYRSA_REQ_PROVINCE "Tuscany"
#set_var EASYRSA_REQ_CITY "Prato"
#set_var EASYRSA_REQ_ORG "MyOrganization"
#set_var EASYRSA_REQ_EMAIL "admin@example.com"
#set_var EASYRSA_REQ_OU "IT Department"
#
# Default certificate validity (in days)
#set_var EASYRSA_CA_EXPIRE 3650
#set_var EASYRSA_CERT_EXPIRE 365
#
# Key size
#set_var EASYRSA_KEY_SIZE 2048
#
# Certificate CN default
#set_var EASYRSA_REQ_CN_DEFAULT "MyCA"
#EOF
#    
#    if [ $? -eq 0 ]; then
#        echo -e "${GREEN}✓ File vars creato con successo: $vars_file${NC}"
#    else
#        echo -e "${RED}✗ Errore nella creazione del file vars${NC}"
#        return 1
#    fi
#}

# Funzione per modificare i parametri VARS
modify_vars_parameters() {
    local vars_file="$1"
    
    echo -e "${BLUE}Modifica parametri VARS${NC}"
    echo "======================"
    echo ""
    echo "Inserisci i nuovi valori (premi INVIO per mantenere il valore attuale):"
    echo ""
    
    # Leggi i valori attuali
    local current_country=$(grep "EASYRSA_REQ_COUNTRY" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
    local current_province=$(grep "EASYRSA_REQ_PROVINCE" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
    local current_city=$(grep "EASYRSA_REQ_CITY" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
    local current_org=$(grep "EASYRSA_REQ_ORG" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
    local current_email=$(grep "EASYRSA_REQ_EMAIL" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
    local current_ou=$(grep "EASYRSA_REQ_OU" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
    local current_cn=$(grep "EASYRSA_REQ_CN_DEFAULT" "$vars_file" 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')
    local current_ca_expire=$(grep "EASYRSA_CA_EXPIRE" "$vars_file" 2>/dev/null | sed -n 's/.*[[:space:]]\([0-9]*\).*/\1/p')
    local current_cert_expire=$(grep "EASYRSA_CERT_EXPIRE" "$vars_file" 2>/dev/null | sed -n 's/.*[[:space:]]\([0-9]*\).*/\1/p')
    local current_key_size=$(grep "EASYRSA_KEY_SIZE" "$vars_file" 2>/dev/null | sed -n 's/.*[[:space:]]\([0-9]*\).*/\1/p')
    
    # Raccolta nuovi valori
    local new_country
    read -p "Paese [$current_country]: " new_country
    new_country=${new_country:-$current_country}
    
    local new_province
    read -p "Provincia [$current_province]: " new_province
    new_province=${new_province:-$current_province}
    
    local new_city
    read -p "Città [$current_city]: " new_city
    new_city=${new_city:-$current_city}
    
    local new_org
    read -p "Organizzazione [$current_org]: " new_org
    new_org=${new_org:-$current_org}
    
    local new_email
    while true; do
        read -p "Email [$current_email]: " new_email
        new_email=${new_email:-$current_email}
        if [[ -z "$new_email" ]] || [[ $new_email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        fi
        echo -e "${RED}Formato email non valido. Riprova.${NC}"
    done
    
    local new_ou
    read -p "Unità Organizzativa [$current_ou]: " new_ou
    new_ou=${new_ou:-$current_ou}
    
    local new_cn
    read -p "Nome CA [$current_cn]: " new_cn
    new_cn=${new_cn:-$current_cn}
    
    local new_ca_expire
    while true; do
        read -p "Scadenza CA in giorni [$current_ca_expire]: " new_ca_expire
        new_ca_expire=${new_ca_expire:-$current_ca_expire}
        if [[ $new_ca_expire =~ ^[0-9]+$ ]] && [ $new_ca_expire -gt 0 ]; then
            break
        fi
        echo -e "${RED}Inserisci un numero valido maggiore di 0.${NC}"
    done
    
    local new_cert_expire
    while true; do
        read -p "Scadenza certificati in giorni [$current_cert_expire]: " new_cert_expire
        new_cert_expire=${new_cert_expire:-$current_cert_expire}
        if [[ $new_cert_expire =~ ^[0-9]+$ ]] && [ $new_cert_expire -gt 0 ]; then
            break
        fi
        echo -e "${RED}Inserisci un numero valido maggiore di 0.${NC}"
    done
    
    local new_key_size
    while true; do
        read -p "Dimensione chiave (2048/4096) [$current_key_size]: " new_key_size
        new_key_size=${new_key_size:-$current_key_size}
        if [[ $new_key_size == "2048" ]] || [[ $new_key_size == "4096" ]]; then
            break
        fi
        echo -e "${RED}Dimensione chiave non valida. Usa 2048 o 4096.${NC}"
    done
    
    # Riepilogo
    echo ""
    echo -e "${BLUE}===== RIEPILOGO NUOVI PARAMETRI =====${NC}"
    echo "Paese: $new_country"
    echo "Provincia: $new_province"
    echo "Città: $new_city"
    echo "Organizzazione: $new_org"
    echo "Email: $new_email"
    echo "Unità Organizzativa: $new_ou"
    echo "Nome CA: $new_cn"
    echo "Digest: sha512 (fisso)"
    echo "Scadenza CA: $new_ca_expire giorni"
    echo "Scadenza certificati: $new_cert_expire giorni"
    echo "Dimensione chiave: $new_key_size bit"
    echo ""
    
    # Conferma finale
    local confirm
    while true; do
        read -p "Confermi l'aggiornamento del file vars? (s/n): " confirm
        case $confirm in
            [Ss]|[Ss][Ii])
                update_vars_file "$vars_file" "$new_country" "$new_province" "$new_city" "$new_org" "$new_email" "$new_ou" "$new_cn" "$new_ca_expire" "$new_cert_expire" "$new_key_size"
                return 0
                ;;
            [Nn]|[Nn][Oo])
                echo -e "${YELLOW}Modifiche annullate.${NC}"
                return 0
                ;;
            *)
                echo -e "${RED}Risposta non valida. Inserisci 's' per sì o 'n' per no.${NC}"
                ;;
        esac
    done
}

# Funzione per aggiornare il file vars
update_vars_file() {
    local vars_file="$1"
    local country="$2"
    local province="$3"
    local city="$4"
    local org="$5"
    local email="$6"
    local ou="$7"
    local cn="$8"
    local ca_expire="$9"
    local cert_expire="${10}"
    local key_size="${11}"
    
    echo -e "${YELLOW}Aggiornamento file vars...${NC}"
    
    # Crea il nuovo contenuto del file vars (sempre con sha512)
    cat > "$vars_file" << EOF
# Easy-RSA 3 parameter settings

# Digest algorithm (always sha512)
set_var EASYRSA_DIGEST "sha512"

# Certificate Authority settings
set_var EASYRSA_REQ_COUNTRY "$country"
set_var EASYRSA_REQ_PROVINCE "$province"
set_var EASYRSA_REQ_CITY "$city"
set_var EASYRSA_REQ_ORG "$org"
set_var EASYRSA_REQ_EMAIL "$email"
set_var EASYRSA_REQ_OU "$ou"

# Default certificate validity (in days)
set_var EASYRSA_CA_EXPIRE $ca_expire
set_var EASYRSA_CERT_EXPIRE $cert_expire

# Key size
set_var EASYRSA_KEY_SIZE $key_size

# Certificate CN default
set_var EASYRSA_REQ_CN_DEFAULT "$cn"
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ File vars aggiornato con successo!${NC}"
        echo ""
        echo -e "${BLUE}Nuovi parametri salvati in: $vars_file${NC}"
    else
        echo -e "${RED}✗ Errore nell'aggiornamento del file vars${NC}"
        return 1
    fi
}