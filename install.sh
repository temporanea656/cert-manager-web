# Funzione per installare i file
install_files() {
    echo -e "${BLUE}Installazione Certificate Manager...${NC}"
    
    # Crea la directory di installazione
    echo -e "${YELLOW}Creazione directory: $INSTALL_DIR${NC}"
    if mkdir -p "$INSTALL_DIR"; then
        echo -e "${GREEN}✓ Directory creata${NC}"
    else
        echo -e "${RED}❌ Errore nella creazione della directory${NC}"
        exit 1
    fi
    
    # Copia il file principale
    echo -e "${YELLOW}Copia file principale...${NC}"
    if cp "cert-manager" "$INSTALL_DIR/"; then
        echo -e "${GREEN}✓ File principale copiato${NC}"
    else
        echo -e "${#!/bin/bash

# Script di installazione per Certificate Manager
# Rende cert-manager disponibile come comando di sistema

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directory di installazione
INSTALL_DIR="/opt/cert-manager"
BIN_LINK="/usr/local/bin/cert-manager"

# Funzione per stampare il titolo
print_title() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}   Certificate Manager Installer     ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

# Funzione per verificare i permessi di root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ Errore: Questo script deve essere eseguito come root${NC}"
        echo -e "${YELLOW}Usa: sudo ./install.sh${NC}"
        exit 1
    fi
}

# Funzione per verificare la struttura dei file
check_files() {
    echo -e "${BLUE}Verifica file necessari...${NC}"
    
    local required_files=(
        "cert-manager"
        "modules/verificaCA.sh"
        "modules/parametriVARS.sh"
        "modules/creazioneCA.sh"
        "modules/creazioneSERVER.sh"
        "modules/creazioneCLIENT.sh"
        "modules/firmaCSR.sh"
        "modules/listaCERTIFICATI.sh"
        "modules/rinnovoCERTIFICATI.sh"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "${GREEN}✓${NC} Trovato: $file"
        else
            echo -e "${RED}❌${NC} Mancante: $file"
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}❌ File mancanti rilevati!${NC}"
        echo -e "${YELLOW}Assicurati che tutti i file siano presenti nella directory corrente.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Tutti i file necessari sono presenti${NC}"
    echo ""
}

# Funzione per installare i file
install_files() {
    echo -e "${BLUE}Installazione Certificate Manager...${NC}"
    
    # Crea la directory di installazione
    echo -e "${YELLOW}Creazione directory: $INSTALL_DIR${NC}"
    if mkdir -p "$INSTALL_DIR"; then
        echo -e "${GREEN}✓ Directory creata${NC}"
    else
        echo -e "${RED}❌ Errore nella creazione della directory${NC}"
        exit 1
    fi
    
    # Copia il file principale
    echo -e "${YELLOW}Copia file principale...${NC}"
    if cp "cert-manager" "$INSTALL_DIR/"; then
        echo -e "${GREEN}✓ File principale copiato${NC}"
    else
        echo -e "${RED}❌ Errore nella copia del file principale${NC}"
        exit 1
    fi
    
    # Copia i moduli
    echo -e "${YELLOW}Copia moduli...${NC}"
    if cp -r "modules" "$INSTALL_DIR/"; then
        echo -e "${GREEN}✓ Moduli copiati${NC}"
    else
        echo -e "${RED}❌ Errore nella copia dei moduli${NC}"
        exit 1
    fi
    
    # Imposta i permessi
    echo -e "${YELLOW}Impostazione permessi...${NC}"
    if chmod +x "$INSTALL_DIR/cert-manager"; then
        echo -e "${GREEN}✓ Permessi impostati${NC}"
    else
        echo -e "${RED}❌ Errore nell'impostazione dei permessi${NC}"
        exit 1
    fi
    
    # Crea il link simbolico
    echo -e "${YELLOW}Creazione comando di sistema...${NC}"
    if ln -sf "$INSTALL_DIR/cert-manager" "$BIN_LINK"; then
        echo -e "${GREEN}✓ Comando cert-manager creato${NC}"
    else
        echo -e "${RED}❌ Errore nella creazione del comando${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}✓ Installazione completata con successo!${NC}"
}

# Funzione per verificare l'installazione
verify_installation() {
    echo -e "${BLUE}Verifica installazione...${NC}"
    
    # Verifica che il comando sia disponibile
    if command -v cert-manager >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Comando cert-manager disponibile${NC}"
        
        # Test rapido
        if cert-manager --version >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Test funzionalità superato${NC}"
        else
            echo -e "${YELLOW}⚠ Il comando esiste ma potrebbe avere problemi${NC}"
        fi
    else
        echo -e "${RED}❌ Comando cert-manager non disponibile${NC}"
        echo -e "${YELLOW}Potrebbe essere necessario riavviare il terminale${NC}"
    fi
    
    echo ""
}

# Funzione per mostrare le informazioni post-installazione
show_post_install() {
    echo -e "${BLUE}===== INSTALLAZIONE COMPLETATA =====${NC}"
    echo ""
    echo -e "${GREEN}Certificate Manager è stato installato con successo!${NC}"
    echo ""
    echo -e "${BLUE}UTILIZZO:${NC}"
    echo -e "  ${YELLOW}cert-manager${NC}           # Avvia il menu interattivo"
    echo -e "  ${YELLOW}cert-manager --help${NC}    # Mostra l'aiuto"
    echo -e "  ${YELLOW}cert-manager --check${NC}   # Verifica rapida del sistema"
    echo ""
    echo -e "${BLUE}DIRECTORY INSTALLAZIONE:${NC}"
    echo -e "  ${YELLOW}$INSTALL_DIR${NC}"
    echo ""
    echo -e "${BLUE}COMANDO:${NC}"
    echo -e "  ${YELLOW}$BIN_LINK${NC}"
    echo ""
    echo -e "${BLUE}PREREQUISITI:${NC}"
    echo -e "  • Easy-RSA deve essere installato:"
    echo -e "    ${YELLOW}sudo apt install easy-rsa${NC} (Ubuntu/Debian)"
    echo -e "    ${YELLOW}sudo yum install easy-rsa${NC} (CentOS/RHEL)"
    echo ""
    echo -e "${GREEN}Puoi ora usare 'cert-manager' da qualsiasi directory!${NC}"
}

# Funzione per la disinstallazione
uninstall() {
    echo -e "${BLUE}Disinstallazione Certificate Manager...${NC}"
    
    # Rimuovi il link simbolico
    if [ -L "$BIN_LINK" ]; then
        rm "$BIN_LINK"
        echo -e "${GREEN}✓ Comando rimosso${NC}"
    fi
    
    # Rimuovi la directory di installazione
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        echo -e "${GREEN}✓ Directory di installazione rimossa${NC}"
    fi
    
    echo -e "${GREEN}✓ Disinstallazione completata${NC}"
}

# Funzione per mostrare l'aiuto
show_help() {
    echo "Certificate Manager Installer"
    echo ""
    echo "UTILIZZO:"
    echo "  sudo ./install.sh [opzione]"
    echo ""
    echo "OPZIONI:"
    echo "  install          Installa Certificate Manager completo (default)"
    echo "  uninstall        Rimuove Certificate Manager dal sistema"
    echo "  setup-workspace  Setup solo workspace Easy-RSA (non installa comando)"
    echo "  --help           Mostra questo messaggio"
    echo ""
    echo "ESEMPI:"
    echo "  sudo ./install.sh"
    echo "  sudo ./install.sh setup-workspace"  
    echo "  sudo ./install.sh uninstall"
    echo ""
    echo "DIRECTORY:"
    echo "  Software:  $INSTALL_DIR"
    echo "  Workspace: $EASYRSA_DIR"
    echo "  Backup:    $BACKUP_DIR"
    echo ""
}

# Funzione principale
main() {
    case "${1:-install}" in
        install)
            print_title
            check_root
            check_files
            install_files
            verify_installation
            show_post_install
            ;;
        uninstall)
            print_title
            check_root
            uninstall
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Opzione non riconosciuta: $1${NC}"
            echo "Usa './install.sh --help' per vedere le opzioni disponibili."
            exit 1
            ;;
    esac
}

# Avvia lo script
main "$@"
