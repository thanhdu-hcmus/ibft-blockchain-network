#!/bin/bash
mkdir ./{quorum,tessera}
wget https://artifacts.consensys.net/public/go-quorum/raw/versions/v24.4.1/geth_v24.4.1_linux_amd64.tar.gz -O geth_v24.4.1_linux_amd64.tar.gz
tar -xzvf geth_v24.4.1_linux_amd64.tar.gz
mv geth quorum/
wget https://s01.oss.sonatype.org/service/local/repositories/releases/content/net/consensys/quorum/tessera/tessera-dist/24.4.2/tessera-dist-24.4.2.tar -O tessera-dist-24.4.2.tar
tar -xf tessera-dist-24.4.2.tar
mv tessera-dist-24.4.2/* tessera/
rm -rf tessera-dist-24.4.2* geth*