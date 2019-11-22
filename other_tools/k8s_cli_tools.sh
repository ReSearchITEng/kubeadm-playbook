
########################
########################
echo "kubectx"

sudo git clone -b master --single-branch https://github.com/ahmetb/kubectx.git /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Bash completions
COMPDIR=$(pkg-config --variable=completionsdir bash-completion)
sudo ln -sf /opt/kubectx/completion/kubens.bash $COMPDIR/kubens
sudo ln -sf /opt/kubectx/completion/kubectx.bash $COMPDIR/kubectx

# Zsh completions
mkdir -p ~/.oh-my-zsh/completions
chmod -R 755 ~/.oh-my-zsh/completions
ln -s /opt/kubectx/completion/kubectx.zsh ~/.oh-my-zsh/completions/_kubectx.zsh
ln -s /opt/kubectx/completion/kubens.zsh ~/.oh-my-zsh/completions/_kubens.zsh

########################
########################
echo "krew (kubectl krew package manager)"
tmpdir="$(mktemp -d)"
cd $tmpdir
curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.3.2/krew.{tar.gz,yaml}"
tar zxvf krew.tar.gz
./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" install \
  --manifest=krew.yaml --archive=krew.tar.gz
cd -
rm -rf $tmpdir
sudo cp ~/.krew/bin/kubectl-krew /usr/local/bin

########################
########################
echo "kubeval"
curl -sSL https://github.com/instrumenta/kubeval/releases/download/0.14.0/kubeval-linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local/bin/
sudo chmod +x /usr/local/bin/kubeval



