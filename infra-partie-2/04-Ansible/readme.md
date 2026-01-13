<h1>ATELIER 4 — Ansible : automatiser le déploiement</h1>

<h2>Objectif</h2>
<p>
Découvrir Ansible et les principes de la configuration as code en automatisant
le déploiement d’un serveur Nginx avec une page HTML personnalisée.
</p>
<p>
Le TP est réalisé <strong>en local</strong>, sans cloud, et de manière <strong>portable</strong> grâce à Docker.
</p>

<hr/>

<h2>Environnement utilisé</h2>
<ul>
  <li>Poste hôte : macOS / Windows / Linux</li>
  <li>Docker Desktop installé et fonctionnel</li>
  <li>Ansible exécuté dans un conteneur Ubuntu</li>
</ul>

<p>
Ce choix permet d’utiliser les modules Ansible Linux (<code>apt</code>, <code>service</code>, etc.)
sans dépendre du système d’exploitation du poste hôte.
</p>

<hr/>

<h2>Étape 1 — Créer le dossier du TP</h2>
<p>Créer un dossier pour ce TP avec les fichiers suivants :</p>

<code>
tp-04-ansible/<br/>
&nbsp;&nbsp;inventory.ini<br/>
&nbsp;&nbsp;playbook.yml<br/>
</code>

<hr/>

<h2>Étape 2 — Créer l’inventaire Ansible</h2>
<p>
Dans le fichier <code>inventory.ini</code>, ajouter :
</p>

<code>
[local]<br/>
localhost ansible_connection=local<br/>
</code>

<p>
Cela indique à Ansible d’exécuter les tâches directement sur la machine locale
(dans notre cas : le conteneur), sans connexion SSH.
</p>

<hr/>

<h2>Étape 3 — Créer le playbook principal</h2>
<p>
Créer le fichier <code>playbook.yml</code> avec le contenu suivant :
</p>

<code>
---<br/>
- name: TP Ansible – Déploiement local sur Ubuntu<br/>
&nbsp;&nbsp;hosts: local<br/>
&nbsp;&nbsp;become: yes<br/><br/>

&nbsp;&nbsp;tasks:<br/>
&nbsp;&nbsp;- name: Mettre à jour la liste des paquets<br/>
&nbsp;&nbsp;&nbsp;&nbsp;apt:<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;update_cache: yes<br/><br/>

&nbsp;&nbsp;- name: Installer Nginx<br/>
&nbsp;&nbsp;&nbsp;&nbsp;apt:<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;name: nginx<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;state: present<br/><br/>

&nbsp;&nbsp;- name: Démarrer et activer le service Nginx<br/>
&nbsp;&nbsp;&nbsp;&nbsp;service:<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;name: nginx<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;state: started<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;enabled: yes<br/><br/>

&nbsp;&nbsp;- name: Déployer une page d'accueil personnalisée<br/>
&nbsp;&nbsp;&nbsp;&nbsp;copy:<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;dest: /var/www/html/index.html<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;content: |<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;html&gt;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;head&gt;&lt;title&gt;TP Ansible&lt;/title&gt;&lt;/head&gt;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;body&gt;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;h1&gt;Bienvenue sur le serveur Nginx géré par Ansible 🚀&lt;/h1&gt;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;/body&gt;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&lt;/html&gt;<br/><br/>

&nbsp;&nbsp;- name: Afficher un message de fin<br/>
&nbsp;&nbsp;&nbsp;&nbsp;debug:<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;msg: "Déploiement Ansible terminé avec succès sur {{ ansible_facts['distribution'] }}"<br/>
</code>

<hr/>

<h2>Étape 4 — Lancer un conteneur Ubuntu avec Ansible</h2>
<p>
Depuis le dossier du TP, lancer le conteneur Ubuntu en montant le dossier courant :
</p>

<code>
docker run -it --rm \<br/>
&nbsp;&nbsp;-v $(pwd):/tp \<br/>
&nbsp;&nbsp;ubuntu:22.04 bash<br/>
</code>

<p>
Le dossier du TP est maintenant accessible dans le conteneur via <code>/tp</code>.
</p>

<hr/>

<h2>Étape 5 — Installer Ansible dans le conteneur</h2>
<p>Dans le conteneur Ubuntu :</p>

<code>
apt update<br/>
apt install -y ansible curl<br/>
</code>

<p>Vérification :</p>
<code>ansible --version</code>

<hr/>

<h2>Étape 6 — Se placer dans le dossier du TP</h2>
<code>
cd /tp<br/>
ls<br/>
</code>

<p>Tu dois voir <code>inventory.ini</code> et <code>playbook.yml</code>.</p>

<hr/>

<h2>Étape 7 — Tester la connexion Ansible</h2>
<code>
ansible -i inventory.ini local -m ping<br/>
</code>

<p>Résultat attendu :</p>
<code>
localhost | SUCCESS =&gt; pong
</code>

<hr/>

<h2>Étape 8 — Exécuter le playbook</h2>
<code>
ansible-playbook -i inventory.ini playbook.yml<br/>
</code>

<p>
Lors de la première exécution, certaines tâches peuvent être en <code>changed</code>.
</p>

<hr/>

<h2>Étape 9 — Vérification du résultat</h2>

<p>Tester le serveur Nginx :</p>
<code>
curl http://localhost<br/>
</code>

<p>Résultat attendu :</p>

<code>
&lt;h1&gt;Bienvenue sur le serveur Nginx géré par Ansible 🚀&lt;/h1&gt;
</code>

<hr/>

<h2>Étape 10 — Tester l’idempotence</h2>
<p>
Modifier volontairement le fichier HTML :
</p>

<code>
echo "KO" &gt; /var/www/html/index.html<br/>
</code>

<p>Puis relancer :</p>

<code>
ansible-playbook -i inventory.ini playbook.yml<br/>
</code>

<p>
La tâche <code>copy</code> doit repasser en <code>changed</code>,
les autres restent en <code>ok</code>.
</p>

<p>
Relancer une troisième fois :
</p>

<code>
ansible-playbook -i inventory.ini playbook.yml<br/>
</code>

<p>
Cette fois, toutes les tâches doivent être en <code>ok</code>.
</p>

<hr/>

<h2>Conclusion</h2>
<p>
Ce TP démontre les principes fondamentaux d’Ansible :
</p>
<ul>
  <li>Automatisation déclarative</li>
  <li>Gestion des services et des fichiers</li>
  <li>Idempotence</li>
  <li>Reproductibilité totale</li>
</ul>

<p>
L’utilisation de Docker permet de garantir un environnement Linux cohérent,
quel que soit le système hôte.
</p>
