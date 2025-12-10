# 🎨 Site FSociety.pt - Mr. Robot Theme

> **Configuração do site principal com tema hacker inspirado em Mr. Robot**

---

## 📋 Índice

1. [Conceito do Site](#-conceito-do-site)
2. [Estrutura de Ficheiros](#-estrutura-de-ficheiros)
3. [HTML Principal](#-html-principal)
4. [CSS (Style)](#-css-style)
5. [JavaScript (Matrix Rain)](#-javascript-matrix-rain)
6. [Nginx VirtualHost](#-nginx-virtualhost)
7. [Assets e Média](#-assets-e-média)
8. [Verificação](#-verificação)
9. [Referências](#-referências)

---

## 🎭 Conceito do Site

### Tema: Mr. Robot / FSociety

| Elemento | Descrição |
|----------|-----------|
| **Estilo** | Hacker aesthetic, terminal-style |
| **Cores** | Verde (#00ff00), Preto (#0d0208), Vermelho (#ff0000) |
| **Fonte** | Anonymous Pro (monospaced) |
| **Efeitos** | Matrix rain, glitch text, terminal animation |
| **Vídeo** | fsociety.mp4 background com overlay |
| **Quote** | "Control is an illusion..." |

---

## 📁 Estrutura de Ficheiros

### Criar Diretórios

```bash
# Criar estrutura
sudo mkdir -p /var/www/fsociety.pt/public_html/{css,js,media,fonts}

# Permissões
sudo chown -R www-data:www-data /var/www/fsociety.pt
sudo chmod -R 755 /var/www/fsociety.pt
```

### Estrutura Final

```
/var/www/fsociety.pt/public_html/
├── index.html              # Página principal
├── css/
│   └── style.css           # Estilos
├── js/
│   ├── matrix.js           # Matrix rain animation
│   └── glitch.js           # Text glitch effects
├── media/
│   ├── fsociety.mp4        # Vídeo de fundo
│   ├── logo.png            # Logo FSociety
│   └── favicon.ico         # Favicon
└── fonts/
    └── anonymous-pro.woff2 # Fonte monospaced
```

---

## 📄 HTML Principal

### index.html

```bash
sudo nano /var/www/fsociety.pt/public_html/index.html
```

Conteúdo:

```html
<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="FSociety - Infraestrutura Empresarial Segura">
    <meta name="keywords" content="fsociety, segurança, infraestrutura, cybersecurity">
    <title>FSociety.pt - Control is an illusion</title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="icon" type="image/x-icon" href="/media/favicon.ico">
</head>
<body>
    <!-- Canvas para Matrix Rain -->
    <canvas id="matrix"></canvas>
    
    <!-- Container principal -->
    <div class="container">
        <!-- Logo -->
        <div class="logo">
            <img src="/media/logo.png" alt="FSociety Logo" class="logo-img">
        </div>
        
        <!-- Terminal -->
        <div class="terminal">
            <div class="terminal-header">
                <span class="terminal-title">fsociety@server:~$</span>
                <div class="terminal-controls">
                    <span class="btn-min"></span>
                    <span class="btn-max"></span>
                    <span class="btn-close"></span>
                </div>
            </div>
            <div class="terminal-body">
                <p class="glitch" data-text="WELCOME TO FSOCIETY.PT">WELCOME TO FSOCIETY.PT</p>
                <p class="typed-text">
                    > Initializing secure connection...<br>
                    > Access granted<br>
                    > Loading infrastructure...<br>
                    <span class="cursor">_</span>
                </p>
                <div class="quote">
                    <p>"Control is an illusion, but chaos... chaos is real."</p>
                    <span class="author">- Mr. Robot</span>
                </div>
            </div>
        </div>
        
        <!-- Services Grid -->
        <div class="services">
            <div class="service-card">
                <h3>📁 Nextcloud</h3>
                <p>Cloud storage e colaboração</p>
                <a href="https://nextcloud.fsociety.pt" class="btn">Aceder</a>
            </div>
            <div class="service-card">
                <h3>📧 Email</h3>
                <p>Servidor de email corporativo</p>
                <a href="https://mail.fsociety.pt" class="btn">Aceder</a>
            </div>
            <div class="service-card">
                <h3>🎫 Tickets</h3>
                <p>Sistema de ticketing</p>
                <a href="https://tickets.fsociety.pt" class="btn">Aceder</a>
            </div>
        </div>
        
        <!-- Footer -->
        <footer>
            <p>FSociety.pt | ESTG/IPP 2025/2026</p>
            <p class="small">Infraestrutura Empresarial Segura</p>
        </footer>
    </div>
    
    <!-- Scripts -->
    <script src="/js/matrix.js"></script>
    <script src="/js/glitch.js"></script>
</body>
</html>
```

---

## 🎨 CSS (Style)

### style.css

```bash
sudo nano /var/www/fsociety.pt/public_html/css/style.css
```

Conteúdo:

```css
/* Fonte */
@font-face {
    font-family: 'Anonymous Pro';
    src: url('/fonts/anonymous-pro.woff2') format('woff2');
    font-weight: normal;
    font-style: normal;
}

/* Reset */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

/* Body */
body {
    font-family: 'Anonymous Pro', 'Courier New', monospace;
    background: #0d0208;
    color: #00ff00;
    overflow-x: hidden;
    position: relative;
}

/* Matrix Canvas */
#matrix {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: 0;
    opacity: 0.3;
}

/* Container */
.container {
    position: relative;
    z-index: 1;
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
}

/* Logo */
.logo {
    margin-bottom: 2rem;
    animation: fadeIn 1s ease-in;
}

.logo-img {
    width: 150px;
    height: auto;
    filter: drop-shadow(0 0 10px #00ff00);
}

/* Terminal */
.terminal {
    background: rgba(0, 0, 0, 0.8);
    border: 2px solid #00ff00;
    border-radius: 8px;
    width: 100%;
    max-width: 800px;
    margin: 2rem 0;
    box-shadow: 0 0 30px rgba(0, 255, 0, 0.3);
    animation: slideUp 1s ease-out;
}

.terminal-header {
    background: #1a1a1a;
    padding: 0.5rem 1rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid #00ff00;
}

.terminal-title {
    color: #00ff00;
    font-size: 0.9rem;
}

.terminal-controls {
    display: flex;
    gap: 8px;
}

.terminal-controls span {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    display: inline-block;
}

.btn-min { background: #00ff00; }
.btn-max { background: #ffff00; }
.btn-close { background: #ff0000; }

.terminal-body {
    padding: 2rem;
    font-size: 1rem;
    line-height: 1.6;
}

/* Glitch Effect */
.glitch {
    font-size: 2rem;
    font-weight: bold;
    text-transform: uppercase;
    position: relative;
    color: #00ff00;
    letter-spacing: 3px;
    animation: glitch 1s infinite;
}

@keyframes glitch {
    0% { text-shadow: 0.05em 0 0 #ff0000, -0.05em -0.025em 0 #00ff00, -0.025em 0.05em 0 #0000ff; }
    14% { text-shadow: 0.05em 0 0 #ff0000, -0.05em -0.025em 0 #00ff00, -0.025em 0.05em 0 #0000ff; }
    15% { text-shadow: -0.05em -0.025em 0 #ff0000, 0.025em 0.025em 0 #00ff00, -0.05em -0.05em 0 #0000ff; }
    49% { text-shadow: -0.05em -0.025em 0 #ff0000, 0.025em 0.025em 0 #00ff00, -0.05em -0.05em 0 #0000ff; }
    50% { text-shadow: 0.025em 0.05em 0 #ff0000, 0.05em 0 0 #00ff00, 0 -0.05em 0 #0000ff; }
    99% { text-shadow: 0.025em 0.05em 0 #ff0000, 0.05em 0 0 #00ff00, 0 -0.05em 0 #0000ff; }
    100% { text-shadow: -0.025em 0 0 #ff0000, -0.025em -0.025em 0 #00ff00, -0.025em -0.05em 0 #0000ff; }
}

/* Typed Text */
.typed-text {
    margin: 2rem 0;
}

.cursor {
    animation: blink 0.7s infinite;
}

@keyframes blink {
    0%, 50% { opacity: 1; }
    51%, 100% { opacity: 0; }
}

/* Quote */
.quote {
    margin-top: 2rem;
    padding: 1rem;
    border-left: 3px solid #00ff00;
    font-style: italic;
}

.author {
    display: block;
    margin-top: 0.5rem;
    text-align: right;
    color: #00cc00;
}

/* Services Grid */
.services {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 2rem;
    width: 100%;
    max-width: 900px;
    margin: 2rem 0;
}

.service-card {
    background: rgba(0, 0, 0, 0.7);
    border: 1px solid #00ff00;
    border-radius: 8px;
    padding: 2rem;
    text-align: center;
    transition: all 0.3s ease;
}

.service-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 10px 30px rgba(0, 255, 0, 0.3);
    border-color: #00ff00;
}

.service-card h3 {
    margin-bottom: 1rem;
    font-size: 1.5rem;
}

.service-card p {
    color: #00cc00;
    margin-bottom: 1.5rem;
}

/* Button */
.btn {
    display: inline-block;
    padding: 0.5rem 1.5rem;
    background: transparent;
    color: #00ff00;
    text-decoration: none;
    border: 1px solid #00ff00;
    border-radius: 4px;
    transition: all 0.3s ease;
}

.btn:hover {
    background: #00ff00;
    color: #0d0208;
}

/* Footer */
footer {
    margin-top: 3rem;
    text-align: center;
    color: #00cc00;
    font-size: 0.9rem;
}

.small {
    font-size: 0.8rem;
    opacity: 0.7;
    margin-top: 0.5rem;
}

/* Animations */
@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}

@keyframes slideUp {
    from {
        opacity: 0;
        transform: translateY(50px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

/* Responsive */
@media (max-width: 768px) {
    .container {
        padding: 1rem;
    }
    
    .terminal-body {
        padding: 1rem;
        font-size: 0.9rem;
    }
    
    .glitch {
        font-size: 1.5rem;
    }
    
    .services {
        grid-template-columns: 1fr;
    }
}
```

---

## 🌧️ JavaScript (Matrix Rain)

### matrix.js

```bash
sudo nano /var/www/fsociety.pt/public_html/js/matrix.js
```

Conteúdo:

```javascript
// Matrix Rain Effect
const canvas = document.getElementById('matrix');
const ctx = canvas.getContext('2d');

// Fullscreen
canvas.width = window.innerWidth;
canvas.height = window.innerHeight;

// Characters
const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()';
const fontSize = 14;
const columns = canvas.width / fontSize;

// Drops
const drops = [];
for (let i = 0; i < columns; i++) {
    drops[i] = Math.random() * -100;
}

// Draw
function draw() {
    // Fade effect
    ctx.fillStyle = 'rgba(13, 2, 8, 0.05)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    ctx.fillStyle = '#00ff00';
    ctx.font = fontSize + 'px monospace';
    
    for (let i = 0; i < drops.length; i++) {
        const text = chars[Math.floor(Math.random() * chars.length)];
        ctx.fillText(text, i * fontSize, drops[i] * fontSize);
        
        if (drops[i] * fontSize > canvas.height && Math.random() > 0.975) {
            drops[i] = 0;
        }
        drops[i]++;
    }
}

// Animation loop
setInterval(draw, 33);

// Resize handler
window.addEventListener('resize', () => {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
});
```

### glitch.js

```bash
sudo nano /var/www/fsociety.pt/public_html/js/glitch.js
```

Conteúdo:

```javascript
// Glitch text effect
const glitchElements = document.querySelectorAll('.glitch');

glitchElements.forEach(element => {
    const text = element.getAttribute('data-text');
    
    setInterval(() => {
        if (Math.random() > 0.9) {
            element.textContent = text
                .split('')
                .map(char => Math.random() > 0.5 ? char : String.fromCharCode(33 + Math.random() * 94))
                .join('');
            
            setTimeout(() => {
                element.textContent = text;
            }, 50);
        }
    }, 100);
});
```

---

## 🌐 Nginx VirtualHost

### 03-fsociety.conf

```bash
sudo nano /etc/nginx/sites-available/03-fsociety.conf
```

Conteúdo:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name fsociety.pt www.fsociety.pt;
    
    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name fsociety.pt www.fsociety.pt;
    
    # SSL Certificate
    ssl_certificate /etc/letsencrypt/live/fsociety.pt/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fsociety.pt/privkey.pem;
    
    # Root directory
    root /var/www/fsociety.pt/public_html;
    index index.html;
    
    # Security headers
    include snippets/security-headers.conf;
    
    # Rate limiting
    limit_req zone=general_limit burst=20 nodelay;
    
    # Logs
    access_log /var/log/nginx/fsociety_access.log main;
    error_log /var/log/nginx/fsociety_error.log;
    
    # Main location
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Cache static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }
}
```

### Ativar Site

```bash
sudo ln -s /etc/nginx/sites-available/03-fsociety.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 📊 Assets e Média

### Download de Fonte

```bash
# Download Anonymous Pro font
cd /tmp
wget https://fonts.google.com/download?family=Anonymous%20Pro -O anonymous-pro.zip
unzip anonymous-pro.zip
sudo cp AnonymousPro-Regular.woff2 /var/www/fsociety.pt/public_html/fonts/anonymous-pro.woff2
```

### Logo e Favicon

Criar/colocar ficheiros:
- `/var/www/fsociety.pt/public_html/media/logo.png`
- `/var/www/fsociety.pt/public_html/media/favicon.ico`

---

## ✅ Verificação

```bash
# Testar site
curl -I https://fsociety.pt

# Browser
firefox https://fsociety.pt
```

---

## 📖 Referências

- [Matrix Digital Rain](https://en.wikipedia.org/wiki/Matrix_digital_rain)
- [CSS Glitch Effect](https://css-tricks.com/glitch-effect/)
- [Mr. Robot TV Series](https://www.imdb.com/title/tt4158110/)

---

<div align="center">

**[⬅️ Voltar: Nginx Config](02-nginx-config.md)** | **[Próximo: Proxy Nextcloud ➡️](04-proxy-nextcloud.md)**

</div>

---

*Última atualização: Dezembro 2025*
