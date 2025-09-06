# Makefile per Certificate Manager
# 
# Comandi disponibili:
#   make install    - Installa cert-manager come comando di sistema
#   make uninstall  - Rimuove cert-manager dal sistema
#   make check      - Verifica i file necessari
#   make clean      - Pulisce file temporanei
#   make help       - Mostra questo messaggio di aiuto

# Variabili
INSTALL_DIR = /opt/cert-manager
BIN_LINK = /usr/local/bin/cert-manager
SCRIPT_FILES = cert-manager modules/verificaCA.sh modules/parametriVARS.sh modules/creazioneCA.sh modules/creazioneSERVER.sh modules/creazioneCLIENT.sh modules/firmaCSR.sh modules/listaCERTIFICATI.sh modules/rinnovoCERTIFICATI.sh

# Colori per output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m

.PHONY: install uninstall check clean help

# Target di default
all: help

# Installazione
install: check-root check-files
	@echo -e "$(YELLOW)Installazione Certificate Manager...$(NC)"
	@mkdir -p $(INSTALL_DIR)
	@cp cert-manager $(INSTALL_DIR)/
	@cp -r modules $(INSTALL_DIR)/
	@chmod +x $(INSTALL_DIR)/cert-manager
	@ln -sf $(INSTALL_DIR)/cert-manager $(BIN_LINK)
	@echo -e "$(GREEN)✓ Certificate Manager installato con successo!$(NC)"
	@echo -e "$(GREEN)✓ Comando 'cert-manager' disponibile$(NC)"
	@echo ""
	@echo -e "$(YELLOW)Prova: cert-manager --help$(NC)"

# Disinstallazione
uninstall: check-root
	@echo -e "$(YELLOW)Disinstallazione Certificate Manager...$(NC)"
	@rm -f $(BIN_LINK)
	@rm -rf $(INSTALL_DIR)
	@echo -e "$(GREEN)✓ Certificate Manager rimosso$(NC)"

# Verifica file necessari
check-files:
	@echo -e "$(YELLOW)Verifica file necessari...$(NC)"
	@for file in $(SCRIPT_FILES); do \
		if [ -f "$$file" ]; then \
			echo -e "$(GREEN)✓$(NC) $$file"; \
		else \
			echo -e "$(RED)❌$(NC) $$file mancante"; \
			exit 1; \
		fi; \
	done
	@echo -e "$(GREEN)✓ Tutti i file sono presenti$(NC)"

# Verifica permessi root
check-root:
	@if [ "$(shell id -u)" != "0" ]; then \
		echo -e "$(RED)❌ Errore: Sono necessari permessi di root$(NC)"; \
		echo -e "$(YELLOW)Usa: sudo make install$(NC)"; \
		exit 1; \
	fi

# Verifica generale
check: check-files
	@echo -e "$(GREEN)✓ Verifica completata$(NC)"
	@if command -v cert-manager >/dev/null 2>&1; then \
		echo -e "$(GREEN)✓ cert-manager già installato$(NC)"; \
		cert-manager --version; \
	else \
		echo -e "$(YELLOW)⚠ cert-manager non installato$(NC)"; \
	fi

# Pulizia file temporanei
clean:
	@echo -e "$(YELLOW)Pulizia file temporanei...$(NC)"
	@find . -name "*~" -delete 2>/dev/null || true
	@find . -name "*.tmp" -delete 2>/dev/null || true
	@echo -e "$(GREEN)✓ Pulizia completata$(NC)"

# Test rapido (senza root)
test:
	@echo -e "$(YELLOW)Test dei moduli...$(NC)"
	@for module in modules/*.sh; do \
		if bash -n "$module"; then \
			echo -e "$(GREEN)✓$(NC) Sintassi OK: $module"; \
		else \
			echo -e "$(RED)❌$(NC) Errore sintassi: $module"; \
		fi; \
	done
	@if bash -n $(MAIN_SCRIPT); then \
		echo -e "$(GREEN)✓$(NC) Sintassi OK: $(MAIN_SCRIPT)"; \
	else \
		echo -e "$(RED)❌$(NC) Errore sintassi: $(MAIN_SCRIPT)"; \
	fi

# Mostra informazioni di aiuto
help:
	@echo "Certificate Manager - Makefile"
	@echo ""
	@echo "COMANDI DISPONIBILI:"
	@echo "  make install    - Installa cert-manager come comando di sistema"
	@echo "  make uninstall  - Rimuove cert-manager dal sistema"
	@echo "  make check      - Verifica i file necessari e lo stato"
	@echo "  make test       - Test sintassi dei file (non richiede root)"
	@echo "  make clean      - Pulisce file temporanei"
	@echo "  make help       - Mostra questo messaggio"
	@echo ""
	@echo "ESEMPI:"
	@echo "  sudo make install     # Installa il sistema"
	@echo "  make test            # Verifica sintassi"
	@echo "  sudo make uninstall  # Rimuove il sistema"
	@echo ""
	@echo "DOPO L'INSTALLAZIONE:"
	@echo "  cert-manager          # Avvia il menu interattivo"
	@echo "  cert-manager --help   # Mostra l'aiuto"
	@echo "  cert-manager --check  # Verifica rapida"

# Informazioni sul sistema
info:
	@echo "Certificate Manager - Informazioni Sistema"
	@echo ""
	@echo "DIRECTORY:"
	@echo "  Installazione: $(INSTALL_DIR)"
	@echo "  Comando:       $(BIN_LINK)"
	@echo ""
	@echo "STATO:"
	@if [ -d "$(INSTALL_DIR)" ]; then \
		echo -e "  Directory:     $(GREEN)✓ Presente$(NC)"; \
	else \
		echo -e "  Directory:     $(RED)❌ Non presente$(NC)"; \
	fi
	@if [ -L "$(BIN_LINK)" ]; then \
		echo -e "  Comando:       $(GREEN)✓ Installato$(NC)"; \
	else \
		echo -e "  Comando:       $(RED)❌ Non installato$(NC)"; \
	fi
	@echo ""
	@echo "PREREQUISITI:"
	@if command -v openssl >/dev/null 2>&1; then \
		echo -e "  OpenSSL:       $(GREEN)✓ Installato$(NC)"; \
	else \
		echo -e "  OpenSSL:       $(RED)❌ Non trovato$(NC)"; \
	fi
	@if [ -d "/etc/easy-rsa" ]; then \
		echo -e "  Easy-RSA:      $(GREEN)✓ Installato$(NC)"; \
	else \
		echo -e "  Easy-RSA:      $(RED)❌ Non trovato$(NC)"; \
	fi
