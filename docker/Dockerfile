FROM ensemblorg/ensembl-vep:release_108.2

MAINTAINER Matthias Munz <matthias.munz@gmx.de>

# Change user to root
USER root

RUN apt-get update && apt-get install -y samtools git

# Change user to vep
USER vep

RUN perl INSTALL.pl \
        --AUTO fcp \
        --NO_UPDATE \
        --ASSEMBLY GRCh38 \
        --PLUGINSDIR /opt/vep/.vep/Plugins/ \
        --CACHEDIR /opt/vep/.vep/ \
        --PLUGINS all \
        --SPECIES homo_sapiens && \
    vep -id rs699 \
      --cache \
      --nearest symbol \
      -o 'STDOUT' \
      --no_stats \
      > /dev/null

# Change user to root
USER root

RUN mkdir /home/git && \
     cd /home/git && \
     git clone --single-branch --branch grch38 https://github.com/konradjk/loftee.git
RUN cp -r /home/git/loftee/* /opt/vep/.vep/Plugins/

RUN export PERL5LIB=/opt/vep/.vep/Plugins:$PERL5LIB

RUN apt-get update && apt-get install -y cpanminus

RUN cpanm DBD::SQLite::VirtualTable::PerlData

RUN cpanm Bio::DB::BigBed

RUN apt-get update && apt-get install -y time

RUN apt-get update && apt-get install -y axel

RUN cd /opt/vep/.vep/Plugins/

RUN axel -n 4 https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/gerp_conservation_scores.homo_sapiens.GRCh38.bw 

RUN mv gerp_conservation_scores.homo_sapiens.GRCh38.bw /opt/vep/.vep/Plugins/

RUN apt-get update && apt-get install -y bcftools

# Change user to vep
USER vep
