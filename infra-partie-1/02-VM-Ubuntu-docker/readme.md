<h1>Créer une VM Ubuntu et y lancer un conteneur Nginx</h1>
<p>Objectif: <br/>Mettre en place une machine virtuelle Ubuntu Server 
(sous VirtualBox), y installer Docker, 
puis exécuter Nginx en conteneur accessible depuis ta machine hôte.</p>
<h2>Étape 1 – Pré-requis</h2>
<p>Vérifie que VirtualBox est installé :</p>
<code>VBoxManage --version
</code>
<p>Télécharge l’ISO d’Ubuntu Server LTS :</p>
<a href="https://ubuntu.com/download/server">Lien vers l’ISO d’Ubuntu Server LTS</a>
<p>Validation attendue : <br/>
La commande VirtualBox affiche une version (ex: 7.0.20)<br/>
Tu disposes d’un fichier ISO, par exemple ubuntu-24.04-live-server-amd64.iso
</p>
<p>Si ça rate : <br/>

Installe VirtualBox depuis :<br/>
<a href="https://www.virtualbox.org/wiki/Downloads">Lien vers la page d'installation de VirtualBox</a><br/>
Garde l’ISO dans un dossier facilement accessible
</p>
<h2>Étape 2 – Créer la VM</h2>
<ol>
<li>Ouvre VirtualBox → Nouvelle machine</li>
<li>Donne un nom, par ex. : UbuntuDev</li>
<li>Type : Linux, Version : Ubuntu (64-bit)</li>
<li>Mémoire : 2048 Mo</li>
<li>Disque dur : Créer un disque virtuel maintenant :
<ul><li>Type : VDI</li>
<li>Taille : 20 Go
</li>
<li>Allocation : dynamique</li>
</ul>
</li>
</ol>
<p>Validation attendue :
Tu vois UbuntuDev dans la liste des machines VirtualBox
</p>
<h2>Étape 3 – Monter l’ISO Ubuntu</h2>
<ul>
<li>Sélectionne la VM → Configuration → Stockage</li>
<li>Dans Contrôleur IDE, ajoute ton ISO Ubuntu comme lecteur optique.</li>
<li>Démarre la VM → l’installation Ubuntu démarre.Sélectionne la VM → Configuration → Stockage</li>
<li>Dans Contrôleur IDE, ajoute ton ISO Ubuntu comme lecteur optique.</li>
<li>Lance la VM → l’installation Ubuntu démarre.</li>
</ul>
<p>Validation attendue : L’écran d’installation d’Ubuntu s’affiche 
(fond violet/noir avec menu).
</p>
<p>Si ça rate : Vérifie que tu as bien attaché l’ISO à la VM.</p>
<h2>Étape 4 — Lancer l’installation d’Ubuntu</h2>
<ol>
<li>Sélectionne ta VM UbuntuDev.</li>

<li>Clique sur Afficher → Démarrage normal (ou double-clique).</li>

<li>Attends que l’écran de démarrage Ubuntu apparaisse :<br/>
tu verras un écran violet/noir avec un menu :
<code>
Try or install Ubuntu Server
Install Ubuntu Server
OEM install
</code><br/>
choisis la première option par défaut : Try or install Ubuntu Server.
</li>
</ol>
<p>
Pendant l’installation :<br/>

Laisse tous les choix par défaut, sauf :<br/>

Langue : Français (ou Anglais si tu préfères les commandes)<br/>

Réseau : automatique (DHCP)<br/>

Disque : “Utiliser tout le disque”<br/>

Proxy : vide<br/>

Miroir : par défaut<br/>

Coche “Installer le serveur SSH” (facultatif mais recommandé)<br/>

Crée ton utilisateur (par ex. : student, mot de passe student).
</p>
<p>
Validation attendue :<br/>

À la fin, tu dois voir :<br/>
<code>
Installation complete
Remove the installation medium and press ENTER
</code><br/>
<em>Ne redémarre pas tout de suite à ce moment-là !</em>
On doit retirer l’ISO avant d’appuyer sur Entrée.
</p>
<h2>Étape 5 — Retirer le disque d’installation (ISO)</h2>
<ol>
<li>Dans VirtualBox → sélectionne UbuntuDev.</li>

<li>Clique sur Configuration → Stockage.</li>

<li>Clique sur ton ISO Ubuntu sous Contrôleur IDE.</li>

<li>À droite, clique sur l’icône 💿 → Retirer le disque du lecteur virtuel.</li>

<li>Clique sur OK.</li>
</ol>
<p>Validation attendue : Dans le menu Stockage, tu ne vois plus de fichier ISO monté.</p>
<h2>Étape 6 — Premier démarrage de la VM</h2>
<ol>
<li>Reviens à la fenêtre de la VM (l’écran d’installation).</li>

<li>Appuie sur Entrée pour redémarrer.</li>

<li>Laisse Ubuntu démarrer (tu peux voir quelques lignes de texte, c’est normal).</li>
<li>Attends d’arriver sur :<br/>
<code>Ubuntu 24.04 LTS login:
</code>
</li>
</ol>
<h2>Étape 7 — Première connexion</h2>
<ol>
<li>Entre le nom d’utilisateur créé à l’installation (ex. student).</li>

<li>Tape ton mot de passe (il ne s’affiche pas, c’est normal).</li>

<li>Appuie sur Entrée.</li>
</ol>
<p>Validation attendue, tu vois ton shell :<br/>
<code>student@ubuntu:~$
</code>
</p>
<h2>Étape 8 — Vérifier la connexion réseau</h2>
<p>Avant d’installer quoi que ce soit, on s’assure que ta VM a bien accès à Internet.</p>
<p>Dans ta VM (shell Ubuntu), tape :<br/>
<code>ping -c 3 google.com
</code>
</p>
<p>Validation attendue :

Tu dois voir quelque chose comme :
<code>PING google.com (142.250.xxx.xxx) ...
3 packets transmitted, 3 received, 0% packet loss
</code>
Cela prouve que ta VM accède à Internet.
</p>
<p>
Si ça rate : <br/>

Si tu vois “Temporary failure in name resolution” :<br/>

Dans VirtualBox → Configuration → Réseau<br/>

Vérifie que l’Adaptateur 1 est bien en Mode NAT<br/>

Clique sur OK, redémarre la VM et refais le ping.
</p>
<h2>Étape 9 — Mettre à jour la VM</h2>
C’est une bonne pratique avant d’ajouter Docker.
<code>sudo apt update && sudo apt upgrade -y
</code>
<p>Cette commande : met à jour la liste des paquets et installe les dernières mises à jour de sécurité.</p>
<p>Si le terminal reste bloqué sur “Configuring grub…” ou “restart services”, tu peux valider les options par défaut avec Entrée ou Tab + Entrée.</p>
<h2>Étape 10 — Installer Docker dans la VM</h2>
<p>Ubuntu a un paquet docker.io prêt à l’emploi.</p>
<code>sudo apt install -y docker.io
</code>
<p>Ensuite, démarre et active Docker :</p>
<code>sudo systemctl enable --now docker
</code>
<p>Vérifie son état :</p>
<code>sudo systemctl status docker
</code>
<p>Tu dois voir une ligne en vert :</p>
<code>Active: active (running)
</code>
<p>Appuie sur q pour sortir de l’écran du statut.</p>
<h2>Étape 11 — Lancer ton premier conteneur Nginx</h2>
<p>Maintenant, on va vérifier que Docker fonctionne bien en exécutant un serveur web.</p>
<code>sudo docker run -d -p 80:80 --name webserver nginx:latest</code>
<p>
Détails :

-d = mode détaché (en arrière-plan)<br/>

-p 80:80 = expose le port 80 de la VM vers le port 80 du conteneur<br/>

--name webserver = nom du conteneur<br/>

nginx:latest = image Nginx officielle
</p>
<p>
Validation :
Vérifie que le conteneur tourne :
<code>sudo docker ps
</code>
Tu dois voire : <br/>
<code>nginx:latest ... Up ... 0.0.0.0:80->80/tcp
</code>
Teste depuis la VM :<br/>
<code>curl localhost
</code>
Tu dois obtenir :<br/>
<code>
<html>
<head><title>Welcome to nginx!</title></head>
...
</code>
</p>
<h2>Étape 12 — Tester depuis ton PC hôte(facultatif)</h2>
<p>
Éteins la VM :
<code>sudo shutdown now
</code>
Dans VirtualBox → Configuration → Réseau : passe l’Adaptateur 1 en mode Accès par pont
Relance la VM :
<code>student@ubuntu:~$ ip a
</code>
Repère une IP du type 192.168.x.x<br/>
Sur ton PC → ouvre ton navigateur à cette adresse :<br/>
http://192.168.x.x
</p>
<h2>Étape 13 — Nettoyage</h2>
<p>Pour supprimer le conteneur :
<code>sudo docker rm -f webserver
</code>
Pour vérifier qu’il est bien supprimé :
<code>sudo docker ps
</code>
</p>
Tu as maintenant :
<ul>
<li>une VM Ubuntu propre,</li>

<li>Docker fonctionnel,</li>

<li>et ton premier conteneur Nginx déployé.</li>
</ul>



