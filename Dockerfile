# shiny-it — imagem de produção
#
# Base geoespacial do Rocker: já traz R 4.5.2 + GDAL/GEOS/PROJ/UDUNITS compilados,
# eliminando a parte mais lenta e frágil de instalar sf/terra/units.
FROM rocker/geospatial:4.5.2

# Desliga o autoloader do renv: instalamos as deps na biblioteca do sistema e
# rodamos o app contra ela, sem bootstrap project-local dentro do container.
ENV RENV_CONFIG_AUTOLOADER_ENABLED=FALSE

WORKDIR /srv/shiny-app

# 1) Restaura as dependências R primeiro (camada cacheada; só refaz quando renv.lock muda).
#    Aponta o renv para os binários do Posit Public Package Manager do MESMO codinome
#    Ubuntu da imagem base (ex.: noble) — evita compilar sf/terra/arrow do fonte.
COPY renv.lock renv.lock
RUN . /etc/os-release && \
    export RENV_CONFIG_REPOS_OVERRIDE="https://packagemanager.posit.co/cran/__linux__/${VERSION_CODENAME}/latest" && \
    R -e "install.packages('renv'); renv::restore(library = .libPaths()[1], prompt = FALSE)"

# 2) Código do app + dados de runtime (mudam com frequência; ficam após a camada lenta)
COPY . .

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('.', host = '0.0.0.0', port = 3838, launch.browser = FALSE)"]
