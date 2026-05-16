Para compilar uma nova versão da fonte é necessário clonar o repositório do isoevka, instalar algumas dependencias e então compilar o projeto

git clone https://github.com/be5invis/Iosevka.git
cd Iosevka
brew install ttfautohint
npm install
npm run build -- ttf::IosevkaCustom
ou
npm run build -- contents::private-build-plans.sample.toml
brew uninstall ttfautohint
