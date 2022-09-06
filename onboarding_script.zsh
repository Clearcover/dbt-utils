### The most up-to-date documentation for this onboarding script is here:
# - https://clearcover.atlassian.net/wiki/spaces/BI/pages/927334672/How+to+get+started+on+the+BI+Team+on+Day+One

### Things to do BEFORE running this script
# - Open Terminal and run `xcode-select --install` to be sure xcode tools are installed
# - Know your computer’s password (the one to login to the actual computer), it will be asked for multiple times during installation
# - Create Access Token in Github with the "Repo" checkbox marked, Enable SSO for that Access Token, Copy token, will require as password when cloning repos
# - Once again, when you get to the cloning repos portion it will ask for github username and password, the username is the
# 	your usual github handle, the password will be the access token you created and copied
# - When ready to run, run "zsh onboarding.zsh" in the root directory of this repo

### Things to do AFTER running this script
# - One of the last things to print should be your public key, copy and send over to member of CCDE team
# - Be sure to save the workspace that has opened in VScode at the completion of the script
# - Sort out account authorization with jetbrains for DataGrip
# - Sort out account authorization with Tableau for Tableau Desktop

# Ensure installation is running on root directory
cd

# install homebrew
# Check if exists
command -v brew >/dev/null 2>&1 || { echo "Installing Homebrew.."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  } >&2;
echo "Homebrew successfully installed"

# adding brew to PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# reload zprofile with updated PATH
source ~/.zprofile

## install git
echo "Installing git.."
brew install git

## install docker and co, will require password to be input
echo "Installing docker.."
brew install docker
brew install docker-compose docker-machine xhyve docker-machine-driver-xhyve
sudo chown root:wheel $(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
sudo chmod u+s $(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve

## install tldr https://tldr.sh/
echo "Installing tldr..."
brew install tldr

## Get oh my zsh (plugins, themes for zsh).
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# Set zsh theme
sed -i '' 's/ZSH_THEME=".*"/ZSH_THEME="bira"/g' ~/.zshrc
sed -i '' 's/plugins=(git)/plugins=(git zsh-autosuggestions jump)/g' ~/.zshrc

# Add Netskope cerificate
echo 'export REQUESTS_CA_BUNDLE=/opt/netskope/netskope-cert-bundle.pem' >> ~/.zshrc

# Fix zsh permissions
chmod 755 /usr/local/share/zsh
chmod 755 /usr/local/share/zsh/site-functions

# source file to get jump working
source ~/.zshrc

## Clone all the relevant repos, will ask for username and password here
echo "Creating the repos folder and cloning the appropriate repos.."
mkdir ~/repos/
cd ~/repos/
# cloning via https
git clone https://github.com/Clearcover/cc-dbt.git
git clone https://github.com/Clearcover/ccbi-prefect.git
git clone https://github.com/Clearcover/Insurance_Product.git
git clone https://github.com/Clearcover/ccde-report-delivery-service.git
git clone https://github.com/Clearcover/ccbi-looker-core.git
# cloning via ssh if above doesn't work
#git clone git@github.com:Clearcover/cc-dbt.git
#git clone git@github.com:Clearcover/ccbi-prefect.git
#git clone git@github.com:Clearcover/Insurance_Product.git
#git clone git@github.com:Clearcover/ccde-report-delivery-service.git
#git clone git@github.com:Clearcover/ccbi-looker-core.git
echo "All repos successfully installed"

## install dbt
echo "Installing dbt.."
brew update
brew tap dbt-labs/dbt
brew install dbt-labs/dbt/dbt-snowflake@1.0.0
brew link dbt-labs/dbt/dbt-snowflake@1.0.0
echo "dbt successfully installed.. Printing version.."
dbt --version
echo "Setting up dbt profile.."
mkdir ~/.dbt
cp ~/repos/cc-dbt/sample_profile.yml ~/.dbt/profiles.yml
echo "dbt profile created.. You will need to edit this file later."

## install visual studio code
echo "Installing VS Code.."
brew install visual-studio-code

## Add refresh command
echo "alias dbt_refresh='dbt clean ; dbt deps ; dbt seed'" >> ~/.zshrc

## install anaconda
echo "Installing anaconda.."
brew install anaconda
echo "export PATH=/usr/local/anaconda3/bin:"$PATH"" >> ~/.zshrc
echo "anaconda installed succesfully"

## Miscellaneous installations that may be required
echo "Installing yarn.."
brew install yarn

## install iterm2
echo "Installing iTerm2.."
cd ~/Downloads
curl https://iterm2.com/downloads/stable/iTerm2-3_3_9.zip > iTerm2.zip
unzip iTerm2.zip &> /dev/null
mv iTerm.app/ /Applications/iTerm.app
spctl --add /Applications/iTerm.app
rm -rf iTerm2.zip
echo "iTerm2 successfully installed.. Adding colors.."

cd ~/Downloads
mkdir -p ${HOME}/iterm2-colors
cd ${HOME}/iterm2-colors
curl https://github.com/mbadolato/iTerm2-Color-Schemes/zipball/master > iterm2-colors.zip
unzip iterm2-colors.zip
rm iterm2-colors.zip
echo "iTerm2 + Colors installed"

## install the dbt completion script
curl https://raw.githubusercontent.com/fishtown-analytics/dbt-completion.bash/master/dbt-completion.bash > ~/.dbt-completion.bash
echo 'autoload -U +X compinit && compinit' >> ~/.zshrc
echo 'autoload -U +X bashcompinit && bashcompinit' >> ~/.zshrc
echo 'source ~/.dbt-completion.bash' >> ~/.zshrc

## Create a new workspace in vs-code with all of the cloned repos
cp ~/repos/cc-dbt/analyst_default_workspace.code-workspace ~/repos/analyst_default_workspace.code-workspace
open ~/repos/analyst_default_workspace.code-workspace

## Install DataGrip
echo "Installing DataGrip"
brew install datagrip
echo "DataGrip has been installed"

# Creating private and public ssh keys
mkdir ~/.ssh
cd ~/.ssh
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -v1 PBE-SHA1-RC4-128 -out rsa_key.p8
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
echo "Copy the entire key below and send the contents to member of CCDE team to give your public key access to snowflake"
echo "$(cat rsa_key.pub)"
echo "Please enter your private key passphase one more time (Will show as you type this time be aware):"
read -r SF_PRIVATE_KEY_PASSPHRASE

export SF_PRIVATE_KEY_PATH=$PWD"/rsa_key.p8"
export SF_PRIVATE_KEY_PASSPHRASE=$SF_PRIVATE_KEY_PASSPHRASE
export ESCAPED_PRIVATE_KEY_PATH=$(echo $SF_PRIVATE_KEY_PATH | sed -e 's/[]\/$*.^[]/\\&/g')

# update the profiles.yml
sed -i -e "s/\$SF_PRIVATE_KEY_PATH/$ESCAPED_PRIVATE_KEY_PATH/g" ~/.dbt/profiles.yml
sed -i -e "s/\$SF_PRIVATE_KEY_PASSPHRASE/$SF_PRIVATE_KEY_PASSPHRASE/g" ~/.dbt/profiles.yml
sed -i -e "s/\$DBT_DEFAULT_DEV_SCHEMA/dbt_${USER/./_}/g" ~/.dbt/profiles.yml
sed -i -e "s/\$SF_USER_EMAIL/$USER@clearcover.com/g" ~/.dbt/profiles.yml

# uncomment following line if AE
sed -i -e "s/\$SF_ROLE/SF_OKTA_BUSINESS_INTELLIGENCE_ENG/g" ~/.dbt/profiles.yml
# uncomment following line if DA
#sed -i -e "s/\$SF_ROLE/SF_OKTA_BUSINESS_INTELLIGENCE_ANALYST/g" ~/.dbt/profiles.yml
# uncomment following line if manager
#sed -i -e "s/\$SF_ROLE/SF_OKTA_BUSINESS_INTELLIGENCE_MGR/g" ~/.dbt/profiles.yml

# checking that packages were installed 
echo "brew version:"
brew --version
echo
echo "git version:"
git --version
echo
echo "docker version:"
docker --version
echo
echo "tldr version:"
tldr --version
echo
echo "code version:"
code --version
echo
echo "dbt version:"
dbt --version
echo
echo "You have reached the end of the onboarding script."