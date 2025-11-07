-- Estrutura inicial do banco de dados do Sistema de Acompanhamento Acadêmico.

CREATE TABLE IF NOT EXISTS estudantes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    matricula TEXT UNIQUE NOT NULL,
    nome TEXT NOT NULL,
    email TEXT,
    senha_hash TEXT NOT NULL,
    perfil TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dados_academicos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    estudante_id INTEGER NOT NULL,
    horas_estudo REAL,
    participacao_projetos INTEGER,
    disciplinas_praticas INTEGER,
    impacto_percebido REAL,
    data_registro DATE,
    FOREIGN KEY (estudante_id) REFERENCES estudantes (id)
);

CREATE TABLE IF NOT EXISTS simulacoes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    estudante_id INTEGER,
    horas_simuladas REAL,
    projetos_simulados INTEGER,
    disciplinas_simuladas INTEGER,
    impacto_previsto REAL,
    risco_previsto TEXT,
    data_simulacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (estudante_id) REFERENCES estudantes (id)
);

CREATE TABLE IF NOT EXISTS alertas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    estudante_id INTEGER,
    tipo TEXT,
    mensagem TEXT,
    lido BOOLEAN DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (estudante_id) REFERENCES estudantes (id)
);

