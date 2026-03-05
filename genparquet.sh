#!/bin/bash

# Script para baixar malha municipal do IBGE e converter para Parquet

echo "Iniciando processamento da malha municipal IBGE 2024..."

# Executa o script R
Rscript download_ibge.R

if [ $? -eq 0 ]; then
    echo "Sucesso: O arquivo Parquet foi gerado."
else
    echo "Erro: Ocorreu uma falha no script R."
    exit 1
fi
