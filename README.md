# Rota de Campo — V1

MVP para rastreamento consentido de equipes de panfletagem em tempo real.

## O que já está implementado
- Administrador cria operação e equipes no Supabase.
- Cada equipe recebe um token/link próprio de rastreamento.
- Panfleteiro abre o link, autoriza GPS e toca em INICIAR.
- Pontos GPS são gravados no banco durante a sessão.
- Botão ENCERRAR interrompe o registro.
- Painel público acompanha trajetos e posição mais recente via mapa Leaflet/OpenStreetMap.
- Distância aproximada é calculada no cliente.

## Arquivos
- `index.html`: entrada / escolha do modo.
- `admin.html`: cria operação/equipes e gera links.
- `track.html`: tela do panfleteiro.
- `public.html`: acompanhamento do contratante.
- `config.js`: URL e chave pública do Supabase.
- `schema.sql`: tabelas, RLS e RPCs.

## Instalação
1. Crie um projeto no Supabase.
2. Rode `schema.sql` no SQL Editor.
3. Em `config.js`, cole Project URL e publishable/anon key. Nunca use service_role no navegador.
4. Hospede estes arquivos em HTTPS (GitHub Pages, Netlify, Vercel etc.). Geolocalização exige contexto seguro em navegadores modernos.
5. Abra `admin.html`, crie uma operação e copie os links gerados.

## Observação importante sobre GPS em segundo plano
Esta V1 usa `navigator.geolocation.watchPosition`. Navegadores móveis podem reduzir/suspender atualizações quando a tela apaga ou a página vai para segundo plano. Para rastreamento contínuo robusto com tela bloqueada, a evolução recomendada é um app nativo/híbrido com permissão de localização em segundo plano.
