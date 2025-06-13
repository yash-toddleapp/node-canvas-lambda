FROM public.ecr.aws/lambda/nodejs:22

ARG OUT=/root/layers
ARG NODE_VERSION=22


RUN dnf update -y && \
    dnf install -y \
        gcc gcc-c++ make glibc-devel libstdc++-devel \
        binutils binutils-devel tar gzip findutils git patch which \
        pciutils procps-ng file elfutils-libelf && \
		dnf -y install cairo-devel pango-devel libjpeg-turbo-devel giflib-devel && \
    dnf clean all

# will be created and become working dir
WORKDIR $OUT/nodejs

RUN npm install --build-from-source \
canvas@3.1.0 \
pdfjs-dist@4.4.168

# will be created and become working dir
WORKDIR $OUT/lib

# gather missing libraries
RUN curl https://raw.githubusercontent.com/ncopa/lddtree/v1.26/lddtree.sh -o $OUT/lddtree.sh \
&& chmod +x $OUT/lddtree.sh \
&& $OUT/lddtree.sh -l $OUT/nodejs/node_modules/canvas/build/Release/canvas.node | grep '^/lib' | sed -r -e '/canvas.node$/d' > libs.txt \
&& if [ -s libs.txt ]; then cp $(cat libs.txt) .; else echo "No libraries found to copy"; fi \
&& rm -f libs.txt

WORKDIR $OUT

# create a single zip file containing both nodejs and lib directories
RUN zip -r -9 node${NODE_VERSION}_canvas_layer.zip nodejs lib
