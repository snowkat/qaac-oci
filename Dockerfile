FROM debian:trixie

RUN mkdir -pm755 /etc/apt/keyrings          \
    && mkdir -p /etc/apt/sources.list.d

# Install prereq for winehq repo
RUN apt-get -y update                                   \
    && apt-get -y install --no-install-recommends       \
        ca-certificates

# Configure Wine sources -- Update for future codenames as needed
COPY ./wine/winehq-archive.key /etc/apt/keyrings
COPY ./wine/winehq-trixie.sources /etc/apt/sources.list.d

# Install Wine stable and xvfb (required for Wine to pretend there's a GUI)
RUN dpkg --add-architecture i386                        \
    && apt-get -y update                                \
    && apt-get -y install --no-install-recommends       \
        winehq-stable                                   \
        xvfb                                            \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /app /work

COPY ./scripts/run-wine.sh /app

ENV WINEPREFIX=/app/winepfx
ENV WINEPATH="c:\\qaac"
ENV WINEDEBUG=-all

# Pre-generate the wine prefix
RUN chmod +x /app/run-wine.sh           \
    && /app/run-wine.sh hostname        \
    && mkdir /app/winepfx/drive_c/qaac

COPY ./staging/* /app/winepfx/drive_c/qaac

ENTRYPOINT ["/app/run-wine.sh"]
CMD ["/app/winepfx/drive_c/qaac/qaac.exe"]
