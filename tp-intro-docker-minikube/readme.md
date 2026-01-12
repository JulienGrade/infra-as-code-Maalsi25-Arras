<h1>TP – Introduction à Docker et Kubernetes avec Minikube</h1><br/>

<h2>Objectifs</h2>
<ul>
  <li>Exécuter une application Node.js sans installer Node.js localement</li>
  <li>Construire une image Docker à partir d’un Dockerfile</li>
  <li>Lancer un conteneur Docker et exposer un service HTTP</li>
  <li>Déployer la même application dans un cluster Kubernetes local avec Minikube</li>
  <li>Comprendre la différence entre Docker (conteneurisation) et Kubernetes (orchestration)</li>
</ul>

<hr/>

<h2>Pré-requis (macOS / Windows)</h2>

<h3>Outils nécessaires</h3>
<ul>
  <li>Docker Desktop (installé et démarré)</li>
  <li>kubectl</li>
  <li>Minikube</li>
</ul>

<h3>Vérifications initiales</h3>
<code>docker --version</code><br/>
<code>docker ps</code><br/>
<code>kubectl version --client</code><br/>
<code>minikube version</code><br/>

<p>
Si une commande n’est pas trouvée :<br/>
- vérifier que l’outil est installé<br/>
- vérifier que Docker Desktop est bien démarré
</p>

<hr/>

<h2>Partie 1 — Docker : exécuter une application Node.js</h2>

<h3>Étape 1 — Dossier du projet</h3>
<p>Se placer dans le dossier du TP :</p>
<code>cd tp-intro-docker-minikube</code><br/>
<code>pwd</code><br/>
<code>ls -la</code><br/>

<p>
Le dossier doit contenir au minimum :<br/>
- <code>readme.md</code>
</p>

<hr/>

<h3>Étape 2 — Créer le serveur Node.js</h3>
<p>Créer un fichier <code>server.js</code> :</p>

<pre><code>const http = require("http");

const PORT = 8080;

const server = http.createServer((req, res) =&gt; {
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("Hello from Docker and Kubernetes!");
});

server.listen(PORT, "0.0.0.0", () =&gt; {
  console.log(`Server running on port ${PORT}`);
});
</code></pre>

<h4>Validation</h4>
<code>ls -la</code><br/>
<p>Le fichier <code>server.js</code> doit être présent.</p>

<hr/>

<h3>Étape 3 — Créer le Dockerfile</h3>
<p>Créer un fichier <code>Dockerfile</code> (sans extension) :</p>

<pre><code>FROM node:22-alpine

WORKDIR /app

COPY server.js .

EXPOSE 8080

CMD ["node", "server.js"]
</code></pre>

<h4>Validation</h4>
<code>ls -la</code><br/>

<hr/>

<h3>Étape 4 — (Recommandé) Créer .dockerignore</h3>
<p>Créer un fichier <code>.dockerignore</code> :</p>

<pre><code>node_modules
.git
.DS_Store
</code></pre>

<hr/>

<h3>Étape 5 — Build de l’image Docker</h3>
<code>docker build -t hello-node:1.0 .</code><br/>

<h4>Validation</h4>
<code>docker images | grep hello-node</code><br/>

<hr/>

<h3>Étape 6 — Lancer le conteneur Docker</h3>
<code>docker run -d --name hello-node -p 8080:8080 hello-node:1.0</code><br/>

<h4>Validations</h4>
<code>docker ps</code><br/>
<code>docker logs --tail=30 hello-node</code><br/>
<code>curl http://localhost:8080</code><br/>

<p><b>Résultat attendu :</b><br/>
<code>Hello from Docker and Kubernetes!</code>
</p>

<hr/>

<h3>Étape 7 — Nettoyage Docker</h3>
<code>docker stop hello-node</code><br/>
<code>docker rm hello-node</code><br/>

<h4>Validation</h4>
<code>docker ps | grep hello-node || echo "Conteneur supprimé"</code><br/>

<hr/>

<h2>Partie 2 — Kubernetes : déploiement avec Minikube</h2>

<h3>Étape 8 — Démarrer Minikube</h3>
<code>minikube start --driver=docker</code><br/>

<h4>Validation</h4>
<code>minikube status</code><br/>
<code>kubectl get nodes</code><br/>
<p>Le nœud doit être en état <code>Ready</code>.</p>

<hr/>

<h3>Étape 9 — Utiliser Docker de Minikube (important)</h3>

<h4>macOS / Linux</h4>
<code>eval $(minikube -p minikube docker-env)</code><br/>

<h4>Windows (PowerShell)</h4>
<code>minikube docker-env | Invoke-Expression</code><br/>

<h4>Validation</h4>
<code>docker ps</code><br/>
<p>Des conteneurs Kubernetes doivent apparaître.</p>

<hr/>

<h3>Étape 10 — Rebuild l’image dans Minikube</h3>
<code>docker build -t hello-node:1.0 .</code><br/>

<h4>Validation</h4>
<code>docker images | grep hello-node</code><br/>

<hr/>

<h3>Étape 11 — Créer le manifeste Kubernetes</h3>
<p>Créer le fichier <code>deployment.yaml</code> :</p>

<pre><code>apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-node
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-node
  template:
    metadata:
      labels:
        app: hello-node
    spec:
      containers:
        - name: hello-node
          image: hello-node:1.0
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: hello-node
spec:
  type: NodePort
  selector:
    app: hello-node
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 30007
</code></pre>

<hr/>

<h3>Étape 12 — Déployer sur Kubernetes</h3>
<code>kubectl apply -f deployment.yaml</code><br/>

<h4>Validations</h4>
<code>kubectl get pods</code><br/>
<code>kubectl get svc</code><br/>
<p>
Attendu :<br/>
- le Pod est <code>Running</code><br/>
- le Service est <code>NodePort</code> sur <code>30007</code>
</p>

<hr/>

<h3>Étape 13 — Accéder à l’application</h3>

<h4>Méthode recommandée</h4>
<code>minikube service hello-node</code><br/>
<p>Le navigateur s’ouvre sur l’application.</p>

<h4>Alternative manuelle</h4>
<code>minikube ip</code><br/>
<p>Puis ouvrir :<br/>
<code>http://&lt;minikube-ip&gt;:30007</code>
</p>

<p><b>Résultat attendu :</b><br/>
<code>Hello from Docker and Kubernetes!</code>
</p>

<hr/>

<h2>Nettoyage final</h2>

<h3>Supprimer les ressources Kubernetes</h3>
<code>kubectl delete -f deployment.yaml</code><br/>

<h3>Arrêter Minikube</h3>
<code>minikube stop</code><br/>

<h3>(Optionnel) Supprimer complètement Minikube</h3>
<code>minikube delete</code><br/>

<h3>Revenir au Docker local (si docker-env Minikube a été activé)</h3>
<code>eval $(minikube docker-env -u)</code><br/>

<hr/>

<h2>Conclusion</h2>
<ul>
  <li>Docker permet d’exécuter une application dans un environnement isolé et reproductible.</li>
  <li>Kubernetes permet d’orchestrer cette exécution via une configuration déclarative (Deployment, Service).</li>
  <li>Minikube offre un cluster local pour apprendre et tester avant un déploiement cloud.</li>
</ul>

<hr/>

<h2>Suite possible</h2>
<ul>
  <li>Ajouter des probes Kubernetes (readiness/liveness)</li>
  <li>Passer le Service en ClusterIP + Ingress</li>
  <li>Introduire Helm</li>
  <li>Automatiser build + deploy en CI/CD</li>
</ul>
